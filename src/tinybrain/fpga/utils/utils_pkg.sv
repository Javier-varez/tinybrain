package utils_pkg;
    parameter integer WordWidth = 32;

    typedef logic [WordWidth-1:0] word_t;

    function automatic word_t bin_to_gray(input word_t i);
        return i ^ (i >> 1);
    endfunction

    function automatic word_t gray_to_bin(input word_t i);
        word_t v = i;
        for (integer i = WordWidth / 2; i > 0; i = i / 2) begin
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
