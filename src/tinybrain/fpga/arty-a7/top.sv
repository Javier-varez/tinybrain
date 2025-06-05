module top (
    input wire        clk_i,    // PSRAM clk
    inout wire [12:0] data_io,  // multiplexed address and data
    input wire        cs_ni,    // chip select, negated.
    input wire        oe_ni,    // output enable, negated
    input wire        we_ni,    // write enable, negated
    input wire        adv_ni    // address valid, negated
);

    logic internal_reset;
    reset u_reset (
        .sys_clk(clk_i),
        .reset  (internal_reset)
    );

    fmc #(
        .AddrWidth(13),
        .DataWidth(13)
    ) u_fmc (
        .rst_i  (internal_reset),
        .clk_i  (clk_i),
        .data_io(data_io),
        .cs_ni  (cs_ni),
        .oe_ni  (oe_ni),
        .we_ni  (we_ni),
        .adv_ni (adv_ni),
        .wait_o (1'bz)
    );



endmodule
