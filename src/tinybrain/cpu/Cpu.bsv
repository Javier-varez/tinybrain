package Cpu;

import Alu::*;
import BranchAlu::*;
import CoreMemory::*;
import Decoder::*;
import RegisterFile::*;
import Types::*;

interface Cpu;
    (* prefix = "" *)
    method Bit#(4) led;

    (* prefix = "", always_enabled *)
    method Action buttons(Bit#(4) btn);

    (* prefix = "" *)
    method Bit#(1) uart_tx;
endinterface

typedef RegFile#(32, Word, RegIndex) CpuRegFile;
typedef TwoPortMemory#(1024) InstDataMemory;

typedef enum { Fetch, Decode, Execute, MemAccess, WriteBack } CpuState deriving(Eq, Bits);

function Word signExtendMemResult(AccessSize access_size, Word word);
    case (access_size) matches
        Byte:
            return signExtend(word[7:0]);
        HalfWord:
            return signExtend(word[15:0]);
        Word:
            return word;
    endcase
endfunction

module mkCpu#(String mem_file)(Empty);
    Reg#(Address) pc <- mkReg(0);
    CpuRegFile register_file <- mkRegFile();
    InstDataMemory memory <- mkTwoPortMemory(mem_file);

    Reg#(CpuState) state <- mkReg(Fetch);
    Reg#(DecodedInstruction) decoded_instruction <- mkRegU();
    Reg#(ControlSignals) control_signals <- mkRegU();
    Reg#(Word) alu_result <- mkRegU();
    Reg#(Word) rs1_val <- mkRegU();
    Reg#(Word) rs2_val <- mkRegU();
    Reg#(Word) next_pc <- mkRegU();

    rule fetch if (state == Fetch);
        memory.load_request_1(LoadRequest { size: Word, address: pc });
        state <= Decode;
    endrule

    rule decode if (state == Decode);
        let instruction <- memory.load_result_1();

        let dec = decodeInstruction(instruction);
        let ctrl = generateControlSignals(dec);

        decoded_instruction <= dec;
        control_signals <= ctrl;
        state <= Execute;
    endrule

    rule execute if (state == Execute);
        let rs1 = register_file.read_port1(decoded_instruction.rs1);
        let rs2 = register_file.read_port2(decoded_instruction.rs2);
        rs1_val <= rs1;
        rs2_val <= rs2;

        let op1;
        let op2;

        if (control_signals.pc_source)
            op1 = pc;
        else
            op1 = rs1;

        if (control_signals.imm_source)
            op2 = decoded_instruction.imm;
        else
            op2 = rs2;

        // Instantiate ALU
        let next_alu_result = alu(op1, op2, control_signals.alu_op);
        alu_result <= next_alu_result;

        // Instantiate Branch ALU
        let branch_taken = branchAlu(rs1, rs2, control_signals.branch_alu_op);

        if (control_signals.branch && branch_taken)
            next_pc <= next_alu_result;
        else
            next_pc <= pc + 4;

        if (control_signals.mem_op)
            state <= MemAccess;
        else if (control_signals.write_back)
            state <= WriteBack;
        else
            begin
                state <= Fetch;
                pc <= pc + 4;
            end
    endrule

    rule mem_access if (state == MemAccess);
        if (control_signals.mem_op_type == Load)
            memory.load_request_2(LoadRequest {
                size: control_signals.mem_access_size,
                address: alu_result
            });
        else
            memory.store_request(StoreRequest {
                size: control_signals.mem_access_size,
                address: alu_result,
                data: rs2_val
            });

        if (control_signals.write_back)
            state <= WriteBack;
        else
            begin
                state <= Fetch;
                pc <= next_pc;
            end
    endrule

    rule write_back if (state == WriteBack);
        let val;

        if (control_signals.mem_op)
        begin
            let mem_result <- memory.load_result_2();
            if (control_signals.mem_sign_extend)
                val = signExtendMemResult(control_signals.mem_access_size, mem_result);
            else
                val = mem_result;
        end
        else if (control_signals.link)
            val = pc + 4;
        else
            val = alu_result;

        register_file.write_port(decoded_instruction.rd, val);
        state <= Fetch;
        pc <= next_pc;
    endrule

endmodule

endpackage
