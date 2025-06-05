package CoreMemory;

import Assert::*;
import Vector::*;
import Types::*;
import RegFile::*;

typedef struct {
    MemOp op;
    AccessSize size;
    Word address;
    Word data;
} MemRequest deriving(Bits, Eq);

typedef struct {
    AccessSize size;
    Word address;
} LoadRequest deriving(Bits, Eq);

typedef struct {
    AccessSize size;
    Word address;
    Word data;
} StoreRequest deriving(Bits, Eq);

interface Memory#(numeric type size);
    // Requests a memory transaction. If it is a load, the value will be visible in response.
    method Action request(MemRequest r);

    // Accesses the value of the memory load request.
    method ActionValue#(Word) response();
endinterface

interface TwoPortMemory#(numeric type size);
    method Action load_request_1(LoadRequest r);
    method Action load_request_2(LoadRequest r);
    method Action store_request(StoreRequest r);

    method ActionValue#(Word) load_result_1();
    method ActionValue#(Word) load_result_2();
endinterface

function WordAddress toWordAddress(Address address);
    return address[31:2];
endfunction

function Byte takeByte(Address address, Word word);
    case (address[1:0]) matches
        2'b00:
            return word[7:0];
        2'b01:
            return word[15:8];
        2'b10:
            return word[23:16];
        2'b11:
            return word[31:24];
    endcase
endfunction

function HalfWord takeHalfWord(Address address, Word word);
    case (address[1]) matches
        1'b0:
            return word[15:0];
        1'b1:
            return word[31:16];
    endcase
endfunction

function Word overrideByte(Address address, Word original, Byte new_value);
    case (address[1:0]) matches
        2'b00:
            return { original[31:8], new_value };
        2'b01:
            return { original[31:16], new_value, original[7:0] };
        2'b10:
            return { original[31:24], new_value, original[15:0] };
        2'b11:
            return { new_value, original[23:0] };
    endcase
endfunction

function Word overrideHalfWord(Address address, Word original, HalfWord new_value);
    case (address[1]) matches
        1'b0:
            return { original[31:16], new_value };
        1'b1:
            return { new_value, original[15:0] };
    endcase
endfunction

module mkMemory#(String file) (Memory#(sizeType));
    WordAddress addrSize = fromInteger(valueOf(sizeType) / 4);

    RegFile#(WordAddress, Word) mem_array <- mkRegFileLoad(file, 0, addrSize - 1);

    Reg#(Word) out_buf <- mkReg(0);
    Reg#(Bool) valid[2] <- mkCReg(2, False);

    method Action request(MemRequest r) if (!valid[1]);
        let wordAddr = toWordAddress(r.address);
        case (r.op) matches
            Load:
                begin
                    let word = mem_array.sub(wordAddr);
                    valid[1] <= True;
                    case (r.size) matches
                        Byte:
                            out_buf <= { 24'b0, takeByte(r.address, word) };
                        HalfWord:
                            out_buf <= { 16'b0, takeHalfWord(r.address, word) };
                        Word:
                            out_buf <= word;
                    endcase
                end
            Store:
                begin
                    let original = mem_array.sub(wordAddr);
                    case (r.size) matches
                        Byte:
                            mem_array.upd(wordAddr, overrideByte(r.address, original, r.data[7:0]));
                        HalfWord:
                            mem_array.upd(wordAddr, overrideHalfWord(r.address, original, r.data[15:0]));
                        Word:
                            mem_array.upd(wordAddr, r.data);
                    endcase
                end
        endcase
    endmethod

    method ActionValue#(Word) response() if (valid[0]);
        valid[0] <= False;
        return out_buf;
    endmethod
endmodule

module mkTwoPortMemory#(String file) (TwoPortMemory#(sizeType));
    WordAddress addrSize = fromInteger(valueOf(sizeType) / 4);

    RegFile#(WordAddress, Word) mem_array <- mkRegFileLoad(file, 0, addrSize - 1);

    Reg#(Word) out_buf_port_1 <- mkReg(0);
    Reg#(Word) out_buf_port_2 <- mkReg(0);
    Reg#(Bool) valid_port_1[2] <- mkCReg(2, False);
    Reg#(Bool) valid_port_2[2] <- mkCReg(2, False);

    method Action load_request_1(LoadRequest r) if (!valid_port_1[1]);
        let wordAddr = toWordAddress(r.address);
        let word = mem_array.sub(wordAddr);
        valid_port_1[1] <= True;
        case (r.size) matches
            Byte:
                out_buf_port_1 <= { 24'b0, takeByte(r.address, word) };
            HalfWord:
                out_buf_port_1 <= { 16'b0, takeHalfWord(r.address, word) };
            Word:
                out_buf_port_1 <= word;
        endcase
    endmethod

    method Action load_request_2(LoadRequest r) if (!valid_port_2[1]);
        let wordAddr = toWordAddress(r.address);
        let word = mem_array.sub(wordAddr);
        valid_port_2[1] <= True;
        case (r.size) matches
            Byte:
                out_buf_port_2 <= { 24'b0, takeByte(r.address, word) };
            HalfWord:
                out_buf_port_2 <= { 16'b0, takeHalfWord(r.address, word) };
            Word:
                out_buf_port_2 <= word;
        endcase
    endmethod

    method Action store_request(StoreRequest r);
        let wordAddr = toWordAddress(r.address);
        let original = mem_array.sub(wordAddr);
        case (r.size) matches
            Byte:
                mem_array.upd(wordAddr, overrideByte(r.address, original, r.data[7:0]));
            HalfWord:
                mem_array.upd(wordAddr, overrideHalfWord(r.address, original, r.data[15:0]));
            Word:
                mem_array.upd(wordAddr, r.data);
        endcase
    endmethod

    method ActionValue#(Word) load_result_1() if (valid_port_1[0]);
        valid_port_1[0] <= False;
        return out_buf_port_1;
    endmethod

    method ActionValue#(Word) load_result_2() if (valid_port_2[0]);
        valid_port_2[0] <= False;
        return out_buf_port_2;
    endmethod

endmodule

endpackage
