package RegisterFile;

import Types::*;
import Vector::*;

interface RegFile#(numeric type size, type stored_type, type index_type);
    method stored_type read_port1(index_type index);
    method stored_type read_port2(index_type index);
    method Action write_port(index_type index, stored_type value);
endinterface

module mkRegFile(RegFile#(size, stored_type, index_type))
    provisos(Literal#(stored_type),
             Bits#(stored_type, st_size),
             PrimIndex#(index_type, idx),
             Bits#(index_type, it_size));
    Vector#(size, Reg#(stored_type)) regs <- replicateM(mkReg(0));

    method stored_type read_port1(index_type index) = regs[index];

    method stored_type read_port2(index_type index) = regs[index];

    method Action write_port(index_type index, stored_type value);
        if (index != 0)
        begin
            regs[index] <= value;
        end
    endmethod
endmodule

endpackage
