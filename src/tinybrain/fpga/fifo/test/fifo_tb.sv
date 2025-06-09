`define CHECK_EQ(a, b)                              \
  if (a !== b) begin                                \
      automatic string s;                           \
      s = $sformatf ("FAIL: 0x%0h != 0x%0h", a, b); \
      $error(s);                                    \
  end

`define CHECK_PROPERTY(prop, description)            \
  assert property (prop)                             \
  else $error($sformatf("FAIL: %s", description))

module fifo_tb ();
    localparam integer ClkPeriodNs = 10;
    localparam integer Size = 10;
    localparam integer EntrySize = 8;

    logic clk_i;
    logic rst_i;
    logic write_req_i;
    logic write_valid_o;
    logic read_req_i;
    logic read_valid_o;
    logic [EntrySize-1:0] data_i;
    logic [EntrySize-1:0] data_o;

    fifo #(
        .Size(Size),
        .EntrySize(EntrySize)
    ) u_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_req_i(write_req_i),
        .write_valid_o(write_valid_o),
        .read_req_i(read_req_i),
        .read_valid_o(read_valid_o),
        .data_i(data_i),
        .data_o(data_o)
    );

    initial begin
        clk_i = 0;
        forever begin
            #(ClkPeriodNs / 2) clk_i = ~clk_i;
        end
    end

    task automatic push(input logic [EntrySize-1:0] data);
        `CHECK_EQ(write_valid_o, 1'b1);
        if (!write_valid_o) begin
            return;
        end

        data_i = data;
        write_req_i = 1'b1;

        @(negedge clk_i);
        write_req_i = 1'b0;

        data_i = {EntrySize{1'bz}};
    endtask

    task automatic pop(output logic [EntrySize-1:0] data);
        `CHECK_EQ(read_valid_o, 1'b1);
        if (!read_valid_o) begin
            return;
        end

        read_req_i = 1'b1;

        @(negedge clk_i);
        data = data_o;
        read_req_i = 1'b0;
    endtask

    task automatic push_and_pop(input logic [EntrySize-1:0] i, output logic [EntrySize-1:0] o);
        `CHECK_EQ(write_valid_o, 1'b1);
        `CHECK_EQ(read_valid_o, 1'b1);
        if (!write_valid_o || !read_valid_o) begin
            return;
        end

        data_i = i;
        read_req_i = 1'b1;
        write_req_i = 1'b1;

        @(negedge clk_i);
        o = data_o;
        read_req_i = 1'b0;
        write_req_i = 1'b0;
    endtask

    logic [EntrySize-1:0] popped_data;
    initial begin
        rst_i = 1;
        write_req_i = 0;
        read_req_i = 0;
        data_i = 0;

        #(100 * ClkPeriodNs);
        rst_i = 0;

        @(posedge clk_i);
        @(negedge clk_i);

        // Check initial state
        `CHECK_EQ(read_valid_o, 1'b0);
        `CHECK_EQ(write_valid_o, 1'b1);

        // Push then pop single entry
        push(8'hAB);

        `CHECK_EQ(read_valid_o, 1'b1);
        `CHECK_EQ(write_valid_o, 1'b1);

        pop(popped_data);
        `CHECK_EQ(popped_data, 8'hAB);

        `CHECK_EQ(read_valid_o, 1'b0);
        `CHECK_EQ(write_valid_o, 1'b1);

        // Push full FIFO, then pop it.
        for (int i = 0; i < Size - 1; i++) begin
            push(i);
            `CHECK_EQ(read_valid_o, 1'b1);
            `CHECK_EQ(write_valid_o, 1'b1);
        end

        push(Size - 1);
        `CHECK_EQ(read_valid_o, 1'b1);
        `CHECK_EQ(write_valid_o, 1'b0);

        for (int i = 0; i < Size - 1; i++) begin
            pop(popped_data);
            `CHECK_EQ(popped_data, i);
            `CHECK_EQ(read_valid_o, 1'b1);
            `CHECK_EQ(write_valid_o, 1'b1);
        end

        pop(popped_data);
        `CHECK_EQ(popped_data, Size - 1);
        `CHECK_EQ(read_valid_o, 1'b0);
        `CHECK_EQ(write_valid_o, 1'b1);

        // concurrent read/write when the fifo is not full
        push(0);
        `CHECK_EQ(read_valid_o, 1'b1);
        `CHECK_EQ(write_valid_o, 1'b1);

        for (int i = 1; i < Size; i++) begin
            push_and_pop(i, popped_data);
            `CHECK_EQ(popped_data, i - 1);
            `CHECK_EQ(read_valid_o, 1'b1);
            `CHECK_EQ(write_valid_o, 1'b1);
        end

        pop(popped_data);
        `CHECK_EQ(popped_data, Size - 1);
        `CHECK_EQ(read_valid_o, 1'b0);
        `CHECK_EQ(write_valid_o, 1'b1);

        $finish();
    end

endmodule
