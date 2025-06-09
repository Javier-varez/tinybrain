module cdc_sync #(
    // Number of synchronization stages
    parameter integer SyncStages = 2,
    // Width of the signal. Note that you might need to use gray codes or
    // other mechanisms to ensure validity.
    parameter integer Width = 1
) (
    input wire clk_i,
    input logic [Width - 1:0] data_i,
    output logic [Width - 1:0] data_o
);

    logic [Width-1:0] sync_q[SyncStages];

    genvar i;
    generate
        for (i = 0; i < SyncStages; i++) begin : g_sync_stages
            always_ff @(posedge clk_i) begin
                if (i == 0) begin
                    sync_q[i] <= data_i;
                end else begin
                    sync_q[i] <= sync_q[i-1];
                end
            end
        end
    endgenerate

    assign data_o = sync_q[SyncStages-1];

endmodule
