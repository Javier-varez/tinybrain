`define CHECK_EQ(a, b)                              \
  if (a !== b) begin                                \
      automatic string s;                           \
      s = $sformatf ("FAIL: 0x%0h != 0x%0h", a, b); \
      $error(s);                                    \
  end

module fmc_tb ();
    localparam integer DataWidth = 16;
    localparam integer AddrWidth = 16;

    logic rst_i;
    logic clk_i;
    logic [DataWidth-1:0] data_o;
    logic [DataWidth-1:0] data_i;
    wire [DataWidth-1:0] data_io;
    logic cs_ni;
    logic oe_ni;
    logic we_ni;
    logic adv_ni;
    logic wait_o;

    fmc fmc (
        .rst_i  (rst_i),
        .clk_i  (clk_i),
        .data_io(data_io),
        .cs_ni  (cs_ni),
        .oe_ni  (oe_ni),
        .we_ni  (we_ni),
        .adv_ni (adv_ni),
        .wait_o (wait_o)
    );

    assign data_io = data_i;
    assign data_o  = data_io;

    initial begin
        rst_i  = 1;
        clk_i  = 0;
        cs_ni  = 1;
        oe_ni  = 1;
        we_ni  = 1;
        adv_ni = 1;
        data_i = 16'hzzzz;
    end

    initial begin
        forever begin
            #5;
            clk_i = !clk_i;
        end
    end

    initial begin
        #100;
        rst_i = 1'b0;
        @(posedge clk_i);
        cs_ni  = 0;
        adv_ni = 0;
        data_i = 16'h1234;
        @(posedge clk_i);
        adv_ni = 1;
        data_i = 16'h6789;
        we_ni  = 0;
        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
        data_i = 16'hABCD;
        @(posedge clk_i);
        data_i = 16'hABAC;

        @(posedge clk_i);
        cs_ni  = 1;
        we_ni  = 1;
        data_i = 16'hzzzz;

        @(posedge clk_i);
        @(posedge clk_i);
        cs_ni  = 0;
        adv_ni = 0;
        data_i = 16'h1234;
        @(posedge clk_i);
        data_i = 16'hzzzz;
        adv_ni = 1;
        oe_ni  = 0;
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hzzzz);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hzzzz);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'h6789);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hABCD);
        cs_ni = 1;
        oe_ni = 1;

        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hzzzz);

        @(posedge clk_i);
        cs_ni  = 0;
        adv_ni = 0;
        data_i = 16'h1235;
        @(posedge clk_i);
        data_i = 16'hzzzz;
        adv_ni = 1;
        oe_ni  = 0;
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hzzzz);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hzzzz);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hABCD);
        @(posedge clk_i);
        `CHECK_EQ(data_o, 16'hABAC);
        cs_ni = 1;
        oe_ni = 1;
        $finish(1);
    end

endmodule
