package RegisterFileTestBench;

import Assert::*;
import Types::*;
import RegisterFile::*;

(* synthesize *)
module mkTestBench (Empty);
    RegFile#(32, Word, RegIndex) reg_file <- mkRegFile();

    Reg#(Bit#(8)) step <- mkReg(0);

    rule keep_stepping;
        step <= step + 1;
    endrule

    rule readPort1_step0 if (step == 0);
        let reg0 = reg_file.read_port1(0);
        $display("reg[0] = %x", reg0);
        dynamicAssert(reg0 == 'h0, "Initial value of reg0 is not correct");
    endrule

    rule readPort2_step0 if (step == 0);
        let reg1 = reg_file.read_port1(1);
        $display("reg[1] = %x", reg1);
        dynamicAssert(reg1 == 'h0, "Initial value of reg1 is not correct");
    endrule

    rule writePort_step0 if (step == 0);
        reg_file.write_port(1, 'h7b);
    endrule

    rule readPort1_step1 if (step == 1);
        let reg0 = reg_file.read_port1(0);
        $display("reg[0] = %x", reg0);
        dynamicAssert(reg0 == 'h0, "reg 0 was written!");
    endrule

    rule readPort2_step1 if (step == 1);
        let reg1 = reg_file.read_port2(1);
        $display("reg[1] = %x", reg1);
        dynamicAssert(reg1 == 'h7b, "reg 1 was not written!");
    endrule

    rule writePort_step1 if (step == 1);
        reg_file.write_port(0, 13);
    endrule

    rule readPort1_step2 if (step == 2);
        let reg0 = reg_file.read_port1(0);
        $display("reg[0] = %x", reg0);
        dynamicAssert(reg0 == 'h0, "reg 0 was written!");
    endrule

    rule readPort2_step2 if (step == 2);
        let reg1 = reg_file.read_port2(1);
        $display("reg[1] = %x", reg1);
        dynamicAssert(reg1 == 'h7b, "reg 1 was modified!");
    endrule

    rule finish if (step == 3);
        $finish;
    endrule

endmodule

endpackage
