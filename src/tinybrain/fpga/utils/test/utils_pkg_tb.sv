`define CHECK_EQ(a, b)                                  \
  if (a !== b) begin                                    \
      $error ($sformatf ("FAIL: 0x%0h != 0x%0h", a, b)); \
  end

module utils_pkg_tb
    import utils_pkg::*;
();

    initial begin
        `CHECK_EQ(bin_to_gray(8'h02), 8'h03);
        `CHECK_EQ(bin_to_gray(8'h45), 8'h67);

        for (int i = 0; i < 9'h100; i++) begin
            `CHECK_EQ(gray_to_bin(bin_to_gray(i)), i);
        end
    end

endmodule
