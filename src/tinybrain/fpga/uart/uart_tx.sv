module uart_tx #(
    parameter integer ClkRate,
    parameter integer BaudRate = 115200,
    parameter integer WordSize = 8
) (
    input  wire                 clk_i,         // Clock input, with ClkRate rate
    input  wire                 rst_i,         // Synchronous reset signal
    input  wire  [WordSize-1:0] data_i,        // Input data
    input  wire                 data_valid_i,  // Validity signal for the input data
    output wire                 data_ack_o,    // Acknowledge signal for the input data.
    output logic                uart_o         // Serial uart output
);
    if (ClkRate < BaudRate) begin : g_check_clk
        $error(
            $sformatf(
                "Illegal values for parameters ClkRate (%0d) and BaudRate (%0d)", ClkRate, BaudRate
            )
        );
    end

    localparam integer Prescaler = ClkRate / BaudRate - 1;

    // The number of bits required to count the bits transmitted with each word
    localparam integer BitCounterBits = $clog2(WordSize);

    // The number of bits required for the prescaler
    localparam integer PrescalerBits = $clog2(Prescaler);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_START,
        ST_TX_IN_PROGRESS,
        ST_STOP
    } state_t;

    // Type for the counter of number of bits left to transmit
    typedef logic [BitCounterBits-1:0] bit_counter_t;

    // Type for the prescaler
    typedef logic [PrescalerBits-1:0] prescaler_t;

    // Type for the word
    typedef logic [WordSize-1:0] word_t;

    state_t state_q, state_d;
    bit_counter_t bit_count_q;
    prescaler_t prescaler_count_q;

    wire prescale_enable = prescaler_count_q == (Prescaler - 1);

    always_ff @(posedge clk_i) begin
        if (rst_i || prescale_enable) begin
            prescaler_count_q <= 0;
        end else begin
            prescaler_count_q <= prescaler_count_q + 1;
        end
    end


    always_ff @(posedge clk_i) begin
        if (rst_i || (state_q == ST_START)) begin
            bit_count_q <= WordSize - 1;
        end else if (prescale_enable) begin
            bit_count_q <= bit_count_q - 1;
        end
    end

    always_comb begin
        state_d = state_q;
        unique case (state_q)
            ST_IDLE:
            if (data_valid_i) begin
                state_d = ST_START;
            end
            ST_START:
            if (prescale_enable) begin
                state_d = ST_TX_IN_PROGRESS;
            end
            ST_TX_IN_PROGRESS:
            if (prescale_enable && (bit_count_q == {BitCounterBits{1'b0}})) begin
                state_d = ST_STOP;
            end
            ST_STOP:
            if (prescale_enable) begin
                state_d = ST_IDLE;
            end
        endcase
    end

    assign data_ack_o = (state_q == ST_IDLE) && data_valid_i;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

    word_t word_q;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            word_q <= {WordSize{1'b0}};
        end else if ((state_q == ST_IDLE) && data_valid_i) begin
            word_q <= data_i;
        end else if ((state_q == ST_TX_IN_PROGRESS) && prescale_enable) begin
            word_q <= {1'b0, word_q[WordSize-1:1]};
        end
    end

    always_comb begin
        unique case (state_q)
            ST_IDLE: uart_o = 1'b1;
            ST_START: uart_o = 1'b0;
            ST_TX_IN_PROGRESS: uart_o = word_q[0];
            ST_STOP: uart_o = 1'b1;
        endcase
    end

endmodule
