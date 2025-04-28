package Decoder;

import Types::*;

function InstrFormat instrFormat(Opcode opcode);
    case (opcode) matches
        Load:
            return Itype;
        LoadFP:
            return Itype;
        MiscMem:
            return Itype;
        OpImm:
            return Itype;
        AuiPc:
            return Utype;
        OpImm32:
            return Itype;
        Store:
            return Stype;
        StoreFP:
            return Stype;
        Amo:
            return Rtype;
        Op:
            return Rtype;
        Lui:
            return Utype;
        Op32:
            return Rtype;
        Madd:
            return Rtype;
        Msub:
            return Rtype;
        NmSub:
            return Rtype;
        NmAdd:
            return Rtype;
        OpFp:
            return Rtype;
        Branch:
            return Btype;
        Jalr:
            return Itype;
        Jal:
            return Jtype;
        System:
            return Itype;
    endcase
endfunction

function DecodedInstruction decodeInstruction(Instruction instruction);
    Opcode opcode = unpack(instruction[6:0]);

    let format = instrFormat(opcode);
    case (format) matches
        Rtype:
            begin
                return DecodedInstruction {
                    opcode: opcode,
                    rd: unpack(instruction[11:7]),
                    rs1: unpack(instruction[19:15]),
                    rs2: unpack(instruction[24:20]),
                    funct3: instruction[14:12],
                    funct7: instruction[31:25],
                    imm: ?
                };
            end
        Itype:
            begin
                return DecodedInstruction {
                    opcode: opcode,
                    rd: unpack(instruction[11:7]),
                    rs1: unpack(instruction[19:15]),
                    rs2: ?,
                    funct3: instruction[14:12],
                    funct7: ?,
                    imm: signExtend(instruction[31:20])
                };
            end
        Stype:
            begin
                Bit#(12) imm = {instruction[31:25], instruction[11:7]};
                return DecodedInstruction {
                    opcode: opcode,
                    rd: ?,
                    rs1: unpack(instruction[19:15]),
                    rs2: unpack(instruction[24:20]),
                    funct3: instruction[14:12],
                    funct7: ?,
                    imm: signExtend(imm)
                };
            end
        Btype:
            begin
                Bit#(13) imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                return DecodedInstruction {
                    opcode: opcode,
                    rd: ?,
                    rs1: unpack(instruction[19:15]),
                    rs2: unpack(instruction[24:20]),
                    funct3: instruction[14:12],
                    funct7: ?,
                    imm: signExtend(imm)
                };
            end
        Utype:
            begin
                Bit#(32) imm = {instruction[31:12], 12'b0};
                return DecodedInstruction {
                    opcode: opcode,
                    rd: unpack(instruction[11:7]),
                    rs1: 5'b0,  // Use reg 0 to add imm
                    rs2: ?,
                    funct3: ?,
                    funct7: ?,
                    imm: signExtend(imm)
                };
            end
        Jtype:
            begin
                Bit#(21) imm = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                return DecodedInstruction {
                    opcode: opcode,
                    rd: unpack(instruction[11:7]),
                    rs1: ?,
                    rs2: ?,
                    funct3: ?,
                    funct7: ?,
                    imm: signExtend(imm)
                };
            end
    endcase
endfunction

function AluOp decodeOpInstAluOp(DecodedInstruction instruction);
    case (instruction.funct3) matches
        3'b000:
            return Add;
        3'b001:
            return Sll;
        3'b010:
            return Slt;
        3'b011:
            return Sltu;
        3'b100:
            return Xor;
        3'b101:
            if (instruction.funct7[5] == 1'b1)
                return Sra;
            else
                return Srl;
        3'b110:
            return Or;
        3'b111:
            return And;
    endcase
endfunction

function BranchAluOp decodeBranchAluOp(Funct3 funct3);
    case (funct3) matches
        3'b000:
            return Beq;
        3'b001:
            return Bne;
        3'b100:
            return Blt;
        3'b101:
            return Bge;
        3'b110:
            return Bltu;
        3'b111:
            return Bgeu;
        default:
            return ?;  // Anything goes
    endcase
endfunction

function AccessSize decodeMemAccessSize(Funct3 funct3);
    case (funct3[1:0]) matches
        2'b00:
            return Byte;
        2'b01:
            return HalfWord;
        2'b10:
            return Word;
        default:
            return ?;  // Anything goes
    endcase
endfunction

function ControlSignals generateControlSignals(DecodedInstruction instruction);
    let def_control_signals = ControlSignals {
        alu_op: Add,
        imm_source: False,
        mem_op: False,
        mem_op_type: Load,
        mem_access_size: Word,
        mem_sign_extend: False,
        write_back: False,
        branch: False,
        link: False,
        pc_source: False,
        branch_alu_op: ?
    };

    case (instruction.opcode) matches
        Load:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: True,
                mem_op_type: Load,
                mem_access_size: decodeMemAccessSize(instruction.funct3),
                mem_sign_extend: instruction.funct3[2] == 0,
                write_back: True,
                branch: False,
                link: False,
                pc_source: False,
                branch_alu_op: ?
            };
        Store:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: True,
                mem_op_type: Store,
                mem_access_size: decodeMemAccessSize(instruction.funct3),
                mem_sign_extend: False,
                write_back: False,
                branch: False,
                link: False,
                pc_source: False,
                branch_alu_op: ?
            };
        OpImm:
            return ControlSignals {
                alu_op: decodeOpInstAluOp(instruction),
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: False,
                link: False,
                pc_source: False,
                branch_alu_op: ?
            };
        AuiPc:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: False,
                link: False,
                pc_source: True,
                branch_alu_op: ?
            };
        Op:
            return ControlSignals {
                alu_op: decodeOpInstAluOp(instruction),
                imm_source: False,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: False,
                link: False,
                pc_source: False,
                branch_alu_op: ?
            };
        Lui:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: False,
                link: False,
                pc_source: False,
                branch_alu_op: ?
            };
        Branch:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: True,
                link: False,
                pc_source: True,
                branch_alu_op: decodeBranchAluOp(instruction.funct3)
            };
        Jalr:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: True,
                link: True,
                pc_source: False,
                branch_alu_op: Always
            };
        Jal:
            return ControlSignals {
                alu_op: Add,
                imm_source: True,
                mem_op: False,
                mem_op_type: ?,
                mem_access_size: ?,
                mem_sign_extend: ?,
                write_back: True,
                branch: True,
                link: True,
                pc_source: True,
                branch_alu_op: Always
            };
        default:
            return def_control_signals;
    endcase
endfunction

endpackage
