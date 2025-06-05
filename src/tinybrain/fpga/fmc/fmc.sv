module fmc #(
    parameter integer AddrWidth = 16,
    parameter integer DataWidth = 16
) (
    input  wire                 rst_i,    // reset line
    input  wire                 clk_i,    // PSRAM clk
    inout  wire [DataWidth-1:0] data_io,  // multiplexed address and data
    input  wire                 cs_ni,    // chip select, negated.
    input  wire                 oe_ni,    // output enable, negated
    input  wire                 we_ni,    // write enable, negated
    input  wire                 adv_ni,   // address valid, negated
    output wire                 wait_o    // wait state
);
    typedef enum {
        ST_RDY,
        ST_DATA_LAT_WAIT_1,
        ST_DATA_LAT_WAIT_2
    } state_t;

    wire write_mem = !cs_ni && adv_ni && !we_ni;
    wire read_mem = !cs_ni && adv_ni && we_ni && !oe_ni;
    wire addr_valid = !cs_ni && !adv_ni;

    state_t state_q, state_d;

    wire drive_bus = read_mem && (state_q == ST_RDY);

    always_comb begin
        state_d = state_q;
        unique case (state_q)
            ST_RDY: begin
                if (addr_valid) begin
                    state_d = ST_DATA_LAT_WAIT_1;
                end
            end
            ST_DATA_LAT_WAIT_1: begin
                state_d = ST_DATA_LAT_WAIT_2;
            end
            ST_DATA_LAT_WAIT_2: begin
                state_d = ST_RDY;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_RDY;
        end else begin
            state_q <= state_d;
        end
    end

    wire [DataWidth-1:0] data_in, data_out;

    fmc_data_bus #(
        .Width(DataWidth)
    ) u_fmc_data_bus (
        .io_data(data_io),
        .in(data_out),
        .out(data_in),
        .tristate_out(!drive_bus)
    );

    logic [AddrWidth-1:0] addr_q;
    wire  [AddrWidth-1:0] addr_d = data_in[AddrWidth-1:0];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            addr_q[AddrWidth-1:0] <= {AddrWidth{1'b0}};
        end else if (state_q == ST_RDY) begin
            if (addr_valid) begin
                addr_q[AddrWidth-1:0] <= addr_d[AddrWidth-1:0];
            end else if (read_mem || write_mem) begin
                addr_q[AddrWidth-1:0] <= addr_q[AddrWidth-1:0] + 1'h1;
            end
        end
    end

    // TODO(ja): Use a FIFO to send memory requests to a different clock
    // domain. This will be needed to implement peripherals and any other
    // logic that is not directly driven by the FMC clock...
    // Alternatively, we could use the FMC clock to drive the whole design.

    // This is a demo to implement some register memory (256 words) for now.
    localparam integer MemSlots = 256;
    localparam integer MemBits = $clog2(MemSlots);
    var logic [DataWidth-1:0] mem[MemSlots];

    always_ff @(posedge clk_i) begin
        if (write_mem) begin
            mem[addr_q[MemBits-1:0]] <= data_in;
        end
    end

    assign data_out[DataWidth-1:0] = mem[addr_q[MemBits-1:0]];

    // TODO(javier-varez): Properly implement the wait signal output
    assign wait_o = 1'b0;

endmodule
