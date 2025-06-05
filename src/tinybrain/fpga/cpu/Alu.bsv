package Alu;

import Types::*;

function Word alu(Word rs1, Word rs2, AluOp op);
    case (op) matches
        Add: return rs1 + rs2;
        Sub: return rs1 - rs2;
        Sll: return rs1 << rs2[4:0];
        Slt:
            begin
                Int#(32) signed_rs1 = unpack(rs1);
                Int#(32) signed_rs2 = unpack(rs2);
                return signed_rs1 < signed_rs2 ? 1 : 0;
            end
        Sltu:
            begin
                UInt#(32) unsigned_rs1 = unpack(rs1);
                UInt#(32) unsigned_rs2 = unpack(rs2);
                return unsigned_rs1 < unsigned_rs2 ? 1 : 0;
            end
        Xor: return rs1 ^ rs2;
        Srl: return zeroExtend(rs1 >> rs2[4:0]);
        Sra:
            begin
                Int#(32) signed_rs1 = unpack(rs1);
                return pack(signed_rs1 >> rs2[4:0]);
            end
        Or: return rs1 | rs2;
        And: return rs1 & rs2;
    endcase
endfunction

endpackage
