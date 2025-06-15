module cdc_fifo
    import utils_pkg::*;
#(
    // Number of synchronization stages
    parameter integer SyncStages = 2,
    // The width of a word in the FIFO.
    parameter integer Width = 8,
    // Must be a power of 2 so that the gray counters work as intended.
    parameter integer Size = 8
) (
    input wire logic read_clk_i,
    input wire logic read_rst_i,

    input wire logic write_clk_i,
    input wire logic write_rst_i,

    input wire logic read_req_i,
    output wire logic read_valid_o,
    output wire logic [Width-1:0] data_o,

    input wire logic write_req_i,
    output wire logic write_valid_o,
    input wire logic [Width-1:0] data_i
);
    // The index is 1 bit larger than it needs to in order to account for the
    // empty/full conditions of the FIFO. This allows the indexes to point to the
    // same FIFO entry (with an index of width IndexWidth-1) and use the MSB of
    // the index to distinguish full (when the 2 MSBs are different in read and
    // write indexes) from empty (when they are equal).
    localparam integer IndexWidth = $clog2(Size) + 1;
    typedef logic [IndexWidth-1:0] index_t;

    if (count_bits(Size) != 1) begin : g_check_fifo_size
        $error($sformatf("Illegal value for parameter Size $0d", Size));
    end

    // Read domain signals
    index_t read_idx_read_clk_q, write_idx_read_clk_q;

    // Write domain signals
    index_t write_idx_write_clk_q, read_idx_write_clk_q;

    wire can_read_read_clk = read_idx_read_clk_q != write_idx_read_clk_q;
    wire will_read_read_clk = can_read_read_clk && read_req_i;
    assign read_valid_o = can_read_read_clk;

    wire can_write_write_clk = read_idx_write_clk_q != (write_idx_write_clk_q ^ ({1'b1, {IndexWidth-1{1'b0}}}));
    wire will_write_write_clk = can_write_write_clk && write_req_i;
    assign write_valid_o = can_write_write_clk;

    // FIFO Memory
    logic [Width-1:0] memory[Size];

    // Reader implementation
    logic [Width-1:0] read_read_clk_q;
    always_ff @(posedge read_clk_i) begin
        if (read_rst_i) begin
            read_read_clk_q <= {Width{1'b0}};
        end else if (will_read_read_clk) begin
            read_read_clk_q <= memory[read_idx_read_clk_q[IndexWidth-2:0]];
        end
    end
    assign data_o = read_read_clk_q;

    always_ff @(posedge read_clk_i) begin
        if (read_rst_i) begin
            read_idx_read_clk_q <= 0;
        end else if (will_read_read_clk) begin
            read_idx_read_clk_q <= read_idx_read_clk_q + 1;
        end
    end

    // Writer implementation
    always_ff @(posedge write_clk_i) begin
        if (!write_rst_i && will_write_write_clk) begin
            memory[write_idx_write_clk_q[IndexWidth-2:0]] <= data_i;
        end
    end

    always_ff @(posedge write_clk_i) begin
        if (write_rst_i) begin
            write_idx_write_clk_q <= 0;
        end else if (will_write_write_clk) begin
            write_idx_write_clk_q <= write_idx_write_clk_q + 1;
        end
    end

    // Domain transitions
    index_t read_idx_write_clk_gray_q;

    cdc_sync #(
        .Width(IndexWidth),
        .SyncStages(SyncStages)
    ) u_fwd_read_idx_to_write_clk_domain (
        .clk_i (write_clk_i),
        .data_i(bin_to_gray(read_idx_read_clk_q)),
        .data_o(read_idx_write_clk_gray_q)
    );
    assign read_idx_write_clk_q = gray_to_bin(read_idx_write_clk_gray_q);

    index_t write_idx_read_clk_gray_q;

    cdc_sync #(
        .Width(IndexWidth),
        .SyncStages(SyncStages)
    ) u_fwd_write_idx_to_read_clk_domain (
        .clk_i (read_clk_i),
        .data_i(bin_to_gray(write_idx_write_clk_q)),
        .data_o(write_idx_read_clk_gray_q)
    );
    assign write_idx_read_clk_q = gray_to_bin(write_idx_read_clk_gray_q);
endmodule
