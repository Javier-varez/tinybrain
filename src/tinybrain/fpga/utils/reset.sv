module reset #(
    parameter integer Cycles = 100
) (
    input  sys_clk,
    output reset
);
    localparam integer NumCntBits = $clog2(Cycles + 1);

    logic [NumCntBits-1:0] counter;

    initial begin
        counter = 0;
    end

    always_ff @(posedge sys_clk) begin
        if (counter < Cycles) begin
            counter <= counter + 1;
        end
    end

    assign reset = counter < Cycles;
endmodule
