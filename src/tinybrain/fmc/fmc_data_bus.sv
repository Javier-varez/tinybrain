module fmc_data_bus #(
    parameter integer Width = 16
) (
    inout wire [Width-1:0] io_data,
    output wire [Width-1:0] out,
    input wire [Width-1:0] in,
    input wire tristate_out
);

    genvar pin_idx;
    generate
        for (pin_idx = 0; pin_idx < Width; pin_idx = pin_idx + 1) begin : gen_pins
            IOBUF #(
                .IOSTANDARD("LVCMOS33")
            ) u_iobuf (
                .IO(io_data[pin_idx]),
                .I (in[pin_idx]),
                .O (out[pin_idx]),
                .T (tristate_out)
            );
        end : gen_pins
    endgenerate

endmodule
