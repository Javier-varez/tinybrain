package TestBench;

import Assert::*;
import Cpu::*;

(* synthesize *)
module mkTestBench (Empty);
    Reg#(Bit#(32)) count <- mkReg(0);
    Empty cpu <- mkCpu("cpu_inst_mem.txt");

    rule counter;
        count <= count + 1;
    endrule

    rule done if (count == 8192);
        $display("Tests done!!");
        $finish;
    endrule

endmodule

endpackage
