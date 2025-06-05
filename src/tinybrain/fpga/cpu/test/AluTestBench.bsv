package AluTestBench;

import Assert::*;
import Alu::*;
import Types::*;

(* synthesize *)
module mkTestBench (Empty);
    staticAssert(alu(21, 12, Add) == 33, "Add failed!");
    staticAssert(alu(21, 12, Sub) == 9, "Sub failed!");
    staticAssert(alu('h15, 10, Sll) == 'h5400, "Sll failed!");
    staticAssert(alu(15, 10, Slt) == 0, "Slt failed!");
    staticAssert(alu(10, 10, Slt) == 0, "Slt failed!");
    staticAssert(alu(9, 10, Slt) == 1, "Slt failed!");
    staticAssert(alu(-9, -8, Slt) == 1, "Slt failed!");
    staticAssert(alu(128, 129, Sltu) == 1, "Sltu failed!");
    staticAssert(alu(129, 128, Sltu) == 0, "Sltu failed!");
    staticAssert(alu('h12, 'h46, Xor) == 'h54, "Xor failed!");
    staticAssert(alu('h12, 'h46, Or) == 'h56, "Or failed!");
    staticAssert(alu('h12, 'h46, And) == 'h02, "And failed!");
    staticAssert(alu('h12, 2, Srl) == 'h04, "Srl failed!");
    staticAssert(alu('hffffff88, 4, Srl) == 'hffffff8, "Srl failed!");
    staticAssert(alu('hffffff88, 4, Sra) == 'hfffffff8, "Sra failed!");

    rule finish;
        $finish;
    endrule
endmodule

endpackage
