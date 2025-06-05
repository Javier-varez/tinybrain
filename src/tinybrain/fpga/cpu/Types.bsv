package Types;

typedef Bit#(32) Word;
typedef Bit#(16) HalfWord;
typedef Bit#(8) Byte;
typedef Bit#(5) RegIndex;

typedef Bit#(32) Address;
typedef Bit#(30) WordAddress;
typedef Bit#(32) Instruction;

typedef Bit#(7) Funct7;
typedef Bit#(3) Funct3;
typedef Bit#(32) Immediate;

typedef enum {
    Load     = 'b000_0011,
    LoadFP   = 'b000_0111,
    MiscMem  = 'b000_1111,
    OpImm    = 'b001_0011,
    AuiPc    = 'b001_0111,
    OpImm32  = 'b001_1011,
    Store    = 'b010_0011,
    StoreFP  = 'b010_0111,
    Amo      = 'b010_1111,
    Op       = 'b011_0011,
    Lui      = 'b011_0111,
    Op32     = 'b011_1011,
    Madd     = 'b100_0011,
    Msub     = 'b100_0111,
    NmSub    = 'b100_1011,
    NmAdd    = 'b100_1111,
    OpFp     = 'b101_0011,
    Branch   = 'b110_0011,
    Jalr     = 'b110_0111,
    Jal      = 'b110_1111,
    System   = 'b111_0011
} Opcode deriving(Bits, Eq);

typedef struct {
    Opcode opcode;
    RegIndex rd;
    RegIndex rs1;
    RegIndex rs2;
    Funct3 funct3;
    Funct7 funct7;
    Immediate imm;
} DecodedInstruction deriving(Bits, Eq);

typedef enum { Rtype, Itype, Stype, Btype, Utype, Jtype } InstrFormat deriving(Bits, Eq);

typedef enum { Add, Sub, Sll, Slt, Sltu, Xor, Srl, Sra, Or, And } AluOp deriving(Bits, Eq);
typedef enum { Always, Beq, Bne, Blt, Bge, Bltu, Bgeu } BranchAluOp deriving(Bits, Eq);

typedef enum { Load, Store } MemOp deriving(Bits, Eq);

typedef enum {
    Byte,
    HalfWord,
    Word
} AccessSize deriving(Bits, Eq);

typedef struct {
    AluOp alu_op;
    Bool imm_source;
    Bool mem_op;
    MemOp mem_op_type;
    AccessSize mem_access_size;
    Bool mem_sign_extend;
    Bool write_back;
    Bool branch;
    Bool link;
    Bool pc_source;
    BranchAluOp branch_alu_op;
} ControlSignals deriving(Bits, Eq);

endpackage
