package DecoderTestBench;

import Assert::*;
import Types::*;
import Decoder::*;

(* synthesize *)
module mkTestBench(Empty);
    rule opImmRule;
        let raw = 'hFF11_8093;
        let instruction = decodeInstruction(raw);
        dynamicAssert(instruction.opcode == OpImm, "Invalid opcode");
        dynamicAssert(instruction.rd == unpack('h1), "Invalid rd");
        dynamicAssert(instruction.rs1 == unpack('h3), "Invalid rs1");
        dynamicAssert(instruction.imm == 32'hFFFF_FFF1, "Invalid imm");

        $display("Instruction %x :", raw);
        $display("\topcode %x", instruction.opcode);
        $display("\trs1 %x", instruction.rs1);
        $display("\trd %x", instruction.rd);
        $display("\timm %x", instruction.imm);
    endrule

    rule finishExec;
        $finish;
    endrule
endmodule

endpackage
