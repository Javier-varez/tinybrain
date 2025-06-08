module fmc_data_bus #(
    parameter integer Width = 16
) (
    inout wire [Width-1:0] io_data,
    output wire [Width-1:0] out,
    input wire [Width-1:0] in,
    input wire tristate_out
);
    assign io_data[Width-1:0] = tristate_out ? {Width{1'bz}} : in[Width-1:0];
    assign out[Width-1:0] = io_data[Width-1:0];

endmodule
