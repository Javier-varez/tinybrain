package BranchAlu;

import Types::*;

function Bool branchAlu(Word rs1, Word rs2, BranchAluOp op);
    Int#(32) srs1 = unpack(rs1);
    Int#(32) srs2 = unpack(rs2);
    UInt#(32) urs1 = unpack(rs1);
    UInt#(32) urs2 = unpack(rs2);

    case (op) matches
        Always:
            return True;
        Beq:
            return rs1 == rs2;
        Bne:
            return rs1 != rs2;
        Blt:
            return srs1 < srs2;
        Bge:
            return srs1 >= srs2;
        Bltu:
            return urs1 < urs2;
        Bgeu:
            return urs1 >= urs2;
    endcase
endfunction

endpackage
