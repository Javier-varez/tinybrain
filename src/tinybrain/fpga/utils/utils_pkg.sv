package utils_pkg;
    parameter integer WordWidth = 8;

    typedef logic [WordWidth-1:0] word_t;

    function automatic word_t bin_to_gray(input word_t i);
        return i ^ (i >> 1);
    endfunction

    function automatic word_t gray_to_bin(input word_t i);
        word_t v = i;
        v = v ^ (v >> 4);
        v = v ^ (v >> 2);
        v = v ^ (v >> 1);
        return v;
    endfunction

endpackage
