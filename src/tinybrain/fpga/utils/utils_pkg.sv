package utils_pkg;
    parameter integer GrayWordWidth = 32;

    function automatic logic [GrayWordWidth-1:0] bin_to_gray(input logic [GrayWordWidth-1:0] i);
        return i ^ (i >> 1);
    endfunction

    function automatic logic [GrayWordWidth-1:0] gray_to_bin(input logic [GrayWordWidth-1:0] i);
        logic [GrayWordWidth-1:0] v = i;
        for (integer i = GrayWordWidth / 2; i > 0; i = i / 2) begin
            v = v ^ (v >> i);
        end
        return v;
    endfunction

    function automatic integer count_bits(input integer i);
        integer n = 0;
        integer v = i;
        while (v > 0) begin
            if (v & 1) begin
                n += 1;
            end
            v = v >> 1;
        end
        return n;
    endfunction

endpackage
