module fifo #(
    parameter integer Size,
    parameter integer Width
) (
    input wire logic clk_i,
    input wire logic rst_i,
    input wire logic write_req_i,
    output wire logic write_valid_o,
    input wire logic read_req_i,
    output wire logic read_valid_o,
    input wire logic [Width-1:0] data_i,
    output wire logic [Width-1:0] data_o
);
    localparam integer IndexBits = $clog2(Size);
    typedef logic [IndexBits-1:0] index_t;

    index_t read_idx_d, read_idx_q;
    index_t write_idx_d, write_idx_q;
    logic full_q;

    logic [Width-1:0] memory[Size];

    wire can_write = !full_q;
    wire can_read = full_q || (read_idx_q != write_idx_q);

    assign write_valid_o = can_write;
    assign read_valid_o  = can_read;

    wire will_read = can_read && read_req_i;
    wire will_write = can_write && write_req_i;

    logic [Width-1:0] read_q;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            read_q <= {Width{1'b0}};
        end else if (will_read) begin
            read_q <= memory[read_idx_q];
        end
    end
    assign data_o = read_q;

    always_ff @(posedge clk_i) begin
        if (!rst_i && will_write) begin
            memory[write_idx_q] <= data_i;
        end
    end

    always_comb begin
        read_idx_d  = read_idx_q;
        write_idx_d = write_idx_q;
        if (will_read) begin
            read_idx_d = read_idx_q + 1;
        end
        if (will_write) begin
            write_idx_d = write_idx_q + 1;
        end

        if (read_idx_d == Size) begin
            read_idx_d = 0;
        end

        if (write_idx_d == Size) begin
            write_idx_d = 0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            read_idx_q <= {IndexBits{1'b0}};
            write_idx_q <= {IndexBits{1'b0}};
            full_q <= 1'b0;
        end else begin
            read_idx_q  <= read_idx_d;
            write_idx_q <= write_idx_d;

            if (will_write && (write_idx_d == read_idx_d)) begin
                full_q <= 1'b1;
            end else if (will_read && !will_write) begin
                full_q <= 1'b0;
            end
        end
    end

endmodule
