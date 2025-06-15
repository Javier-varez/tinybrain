`define CHECK_EQ(a, b)                              \
  if (a !== b) begin                                \
      automatic string s;                           \
      s = $sformatf ("FAIL: 0x%0h != 0x%0h", a, b); \
      $error(s);                                    \
  end

`define CHECK_PROPERTY(prop, description)            \
  assert property (prop)                             \
  else $error($sformatf("FAIL: %s", description))

module cdc_fifo_tb ();
    localparam integer ClkPeriodNs = 10;
    localparam integer Size = 16;
    localparam integer Width = 8;
    localparam integer SyncStages = 2;

    logic clk_i;
    logic rst_i;
    logic write_req_i;
    logic write_valid_o;
    logic read_req_i;
    logic read_valid_o;
    logic [Width-1:0] data_i;
    logic [Width-1:0] data_o;

    cdc_fifo #(
        .Size(Size),
        .Width(Width),
        .SyncStages(SyncStages)
    ) u_dut (
        .read_clk_i(clk_i),
        .read_rst_i(rst_i),
        .write_clk_i(clk_i),
        .write_rst_i(rst_i),
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

    task automatic push(input logic [Width-1:0] data);
        `CHECK_EQ(write_valid_o, 1'b1);
        if (!write_valid_o) begin
            return;
        end

        data_i = data;
        write_req_i = 1'b1;

        @(negedge clk_i);
        write_req_i = 1'b0;

        data_i = {Width{1'bz}};
    endtask

    task automatic pop(output logic [Width-1:0] data);
        `CHECK_EQ(read_valid_o, 1'b1);
        if (!read_valid_o) begin
            return;
        end

        @(negedge clk_i);

        read_req_i = 1'b1;

        @(negedge clk_i);
        data = data_o;
        read_req_i = 1'b0;
    endtask

    task automatic push_and_pop(input logic [Width-1:0] i, output logic [Width-1:0] o);
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

    logic [Width-1:0] popped_data;
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

        // Push then push single entry
        push(8'hAB);

        // Give it a couple more cycles to make sure that the sync stages have
        // done its job
        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);

        `CHECK_EQ(read_valid_o, 1'b1);
        `CHECK_EQ(write_valid_o, 1'b1);

        pop(popped_data);
        `CHECK_EQ(popped_data, 8'hAB);

        `CHECK_EQ(read_valid_o, 1'b0);
        `CHECK_EQ(write_valid_o, 1'b1);

        // Push full FIFO, then pop it.
        for (int i = 0; i < Size - 1; i++) begin
            push(i);
        end

        for (int i = 0; i < Size - 1; i++) begin
            pop(popped_data);
            `CHECK_EQ(popped_data, i);
        end

        $finish();
    end

endmodule
