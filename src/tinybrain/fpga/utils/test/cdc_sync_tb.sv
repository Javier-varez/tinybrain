`define CHECK_PROPERTY(prop, description)            \
  assert property (prop)                             \
  else $error($sformatf("FAIL: %s", description))

module cdc_sync_tb ();
    localparam integer ClkPeriodNs = 10;
    localparam integer SyncStages = 3;
    localparam integer Width = 8;

    logic rst_i;
    logic clk_i;
    logic [Width-1:0] data_i;
    logic [Width-1:0] data_o;

    cdc_sync #(
        .SyncStages(SyncStages),
        .Width(Width)
    ) u_dut (
        .clk_i (clk_i),
        .data_i(data_i),
        .data_o(data_o)
    );

    initial begin
        clk_i = 0;
        forever begin
            #(ClkPeriodNs / 2) clk_i = ~clk_i;
        end
    end

    initial begin
        data_i = 0;
        rst_i  = 1;

        #(ClkPeriodNs * SyncStages);
        rst_i = 0;

        for (int i = 1; i < 256; i++) begin
            @(posedge clk_i);
            #1;
            data_i = i;
        end

        for (int i = 1; i < 256; i++) begin
            @(posedge clk_i);
            #1;
            data_i = i;
        end

        $finish();
    end

    property p_has_n_stages;
        @(posedge clk_i) disable iff (rst_i) data_o === $past(
            data_i, SyncStages
        );
    endproperty

    `CHECK_PROPERTY(p_has_n_stages, "Signal data_o is not delayed by SyncStages");
endmodule
