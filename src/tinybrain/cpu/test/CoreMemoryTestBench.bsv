package CoreMemoryTestBench;

import Assert::*;
import Types::*;
import CoreMemory::*;

(* synthesize *)
module mkTestBench (Empty);
    Reg#(Bit#(8)) step <- mkReg(0);

    // 32 words of memory
    Memory#(32) memory <- mkMemory("core_memory_contents.txt");
    TwoPortMemory#(32) two_port_memory <- mkTwoPortMemory("core_memory_contents.txt");

    rule keep_stepping;
        step <= step + 1;
    endrule

    rule step0_store if (step == 0);
        memory.request(MemRequest{ op: Store, size: Word, address: 4, data: 'h12345678 });
    endrule

    rule step0_store_two_port if (step == 0);
        two_port_memory.store_request(StoreRequest{ size: Word, address: 4, data: 'h12345678 });
    endrule

    rule step0_load_two_port_1 if (step == 0);
        two_port_memory.load_request_1(LoadRequest{ size: Word, address: 4 });
    endrule

    rule step0_load_two_port_2 if (step == 0);
        two_port_memory.load_request_2(LoadRequest{ size: Word, address: 28 });
    endrule

    rule step1_load_issue if (step == 1);
        memory.request(MemRequest{ op: Load, size: Word, address: 4, data: ? });
    endrule

    rule step1_store_two_port if (step == 1);
        two_port_memory.store_request(StoreRequest{ size: Word, address: 28, data: 'h00ffaa55 });
    endrule

    rule step1_load_response_two_port_1 if (step == 1);
        let rsp <- two_port_memory.load_result_1();
        $display("twoPortW[4] = %x", rsp);
        dynamicAssert(rsp == 'h0, "Invalid value at [4]");
    endrule

    rule step1_load_response_two_port_2 if (step == 1);
        let rsp <- two_port_memory.load_result_2();
        $display("twoPortW[28] = %x", rsp);
        dynamicAssert(rsp == 'hDEADC0DE, "Invalid value at [28]");
    endrule

    rule step1_load_two_port_1 if (step == 1);
        two_port_memory.load_request_1(LoadRequest{ size: Word, address: 4 });
    endrule

    rule step1_load_two_port_2 if (step == 1);
        two_port_memory.load_request_2(LoadRequest{ size: Word, address: 28 });
    endrule

    rule step2_load_issue if (step == 2);
        memory.request(MemRequest{ op: Load, size: Word, address: 28, data: ? });
    endrule

    rule step2_load_response if (step == 2);
        let rsp <- memory.response();
        $display("mem[4] = %x", rsp);
        dynamicAssert(rsp == 'h12345678, "Invalid value at [3]");
    endrule

    rule step2_load_response_two_port_1 if (step == 2);
        let rsp <- two_port_memory.load_result_1();
        $display("twoPortW[4] = %x", rsp);
        dynamicAssert(rsp == 'h12345678, "Invalid value at [4]");
    endrule

    rule step2_load_response_two_port_2 if (step == 2);
        let rsp <- two_port_memory.load_result_2();
        $display("twoPortW[28] = %x", rsp);
        dynamicAssert(rsp == 'hDEADC0DE, "Invalid value at [28]");
    endrule

    rule step2_load_two_port_1 if (step == 2);
        two_port_memory.load_request_1(LoadRequest{ size: Word, address: 4 });
    endrule

    rule step2_load_two_port_2 if (step == 2);
        two_port_memory.load_request_2(LoadRequest{ size: Word, address: 28 });
    endrule

    rule step3_load_response if (step == 3);
        let rsp <- memory.response();
        $display("mem[28] = %x", rsp);
        dynamicAssert(rsp == 'hDEADC0DE, "Invalid value at [28]");
    endrule

    rule step3_load_issue if (step == 3);
        memory.request(MemRequest{ op: Load, size: HalfWord, address: 28, data: ? });
    endrule

    rule step3_load_response_two_port_1 if (step == 3);
        let rsp <- two_port_memory.load_result_1();
        $display("twoPortW[4] = %x", rsp);
        dynamicAssert(rsp == 'h12345678, "Invalid value at [4]");
    endrule

    rule step3_load_response_two_port_2 if (step == 3);
        let rsp <- two_port_memory.load_result_2();
        $display("twoPortW[28] = %x", rsp);
        dynamicAssert(rsp == 'h00ffaa55, "Invalid value at [28]");
    endrule

    rule step4_load_response if (step == 4);
        let rsp <- memory.response();
        $display("hw[28] = %x", rsp);
        dynamicAssert(rsp == 'hC0DE, "Invalid value at hw[28]");
    endrule

    rule step4_load_issue if (step == 4);
        memory.request(MemRequest{ op: Load, size: HalfWord, address: 30, data: ? });
    endrule

    rule step5_load_response if (step == 5);
        let rsp <- memory.response();
        $display("hw[30] = %x", rsp);
        dynamicAssert(rsp == 'hDEAD, "Invalid value at hw[30]");
    endrule

    rule step5_load_issue if (step == 5);
        memory.request(MemRequest{ op: Load, size: Byte, address: 28, data: ? });
    endrule

    rule step6_load_response if (step == 6);
        let rsp <- memory.response();
        $display("b[28] = %x", rsp);
        dynamicAssert(rsp == 'hDE, "Invalid value at b[28]");
    endrule

    rule step6_load_issue if (step == 6);
        memory.request(MemRequest{ op: Load, size: Byte, address: 29, data: ? });
    endrule

    rule step7_load_response if (step == 7);
        let rsp <- memory.response();
        $display("b[29] = %x", rsp);
        dynamicAssert(rsp == 'hC0, "Invalid value at b[29]");
    endrule

    rule step7_load_issue if (step == 7);
        memory.request(MemRequest{ op: Load, size: Byte, address: 30, data: ? });
    endrule

    rule step8_load_response if (step == 8);
        let rsp <- memory.response();
        $display("b[30] = %x", rsp);
        dynamicAssert(rsp == 'hAD, "Invalid value at b[30]");
    endrule

    rule step8_load_issue if (step == 8);
        memory.request(MemRequest{ op: Load, size: Byte, address: 31, data: ? });
    endrule

    rule step9_load_response if (step == 9);
        let rsp <- memory.response();
        $display("b[31] = %x", rsp);
        dynamicAssert(rsp == 'hDE, "Invalid value at b[31]");
    endrule

    rule step9_store_issue if (step == 9);
        memory.request(MemRequest{ op: Store, size: Byte, address: 4, data: 'h01 });
    endrule

    rule step10_store_issue if (step == 10);
        memory.request(MemRequest{ op: Store, size: Byte, address: 5, data: 'h23 });
    endrule

    rule step11_store_issue if (step == 11);
        memory.request(MemRequest{ op: Store, size: Byte, address: 6, data: 'h45 });
    endrule

    rule step12_store_issue if (step == 12);
        memory.request(MemRequest{ op: Store, size: Byte, address: 7, data: 'h67 });
    endrule

    rule step13_load_issue if (step == 13);
        memory.request(MemRequest{ op: Load, size: Word, address: 4, data: ? });
    endrule

    rule step14_load_response if (step == 14);
        let rsp <- memory.response();
        $display("w[4] = %x", rsp);
        dynamicAssert(rsp == 'h67452301, "Invalid value at w[4]");
    endrule

    rule step14_store_issue if (step == 14);
        memory.request(MemRequest{ op: Store, size: HalfWord, address: 4, data: 'h0123 });
    endrule

    rule step15_store_issue if (step == 15);
        memory.request(MemRequest{ op: Store, size: HalfWord, address: 6, data: 'h4567 });
    endrule

    rule step16_load_issue if (step == 16);
        memory.request(MemRequest{ op: Load, size: Word, address: 4, data: ? });
    endrule

    rule step17_load_response if (step == 17);
        let rsp <- memory.response();
        $display("w[4] = %x", rsp);
        dynamicAssert(rsp == 'h45670123, "Invalid value at w[4]");
    endrule

    rule step18 if (step == 18);
        $display("Tests done!");
        $finish;
    endrule
endmodule

endpackage
