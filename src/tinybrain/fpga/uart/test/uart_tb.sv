`define CHECK_EQ(a, b)                              \
  if (a !== b) begin                                \
      automatic string s;                           \
      s = $sformatf ("FAIL: 0x%0h != 0x%0h", a, b); \
      $error(s);                                    \
  end

`define CHECK_PROPERTY(prop, description)            \
  assert property (prop)                             \
  else $error($sformatf("FAIL: %s", description))

module uart_tb ();
    localparam integer ClkRate = 100_000_000;
    localparam integer ClkPeriodNs = 1_000_000_000 / ClkRate;
    localparam integer BaudRate = 115200;
    localparam real BaudPeriodNs = ClkPeriodNs * ClkRate / BaudRate;
    localparam integer WordSize = 8;

    typedef logic [WordSize-1:0] word_t;

    logic  clk_i;
    logic  rst_i;
    word_t data_i;
    logic  data_valid_i;
    logic  data_ack_o;
    logic  uart_o;

    uart_tx #(
        .ClkRate (ClkRate),
        .BaudRate(BaudRate),
        .WordSize(WordSize)
    ) u_dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .data_i(data_i),
        .data_valid_i(data_valid_i),
        .data_ack_o(data_ack_o),
        .uart_o(uart_o)
    );

    initial begin
        clk_i = 0;
        forever begin
            #(ClkPeriodNs / 2) clk_i = ~clk_i;
        end
    end

    task automatic send_word(input word_t word);
        @(posedge clk_i);

        data_i = word;
        data_valid_i = 1'b1;

        wait (data_ack_o);
        @(posedge clk_i);
        #(ClkPeriodNs / 2);
        data_valid_i = 1'b0;
    endtask

    initial begin
        rst_i = 1;
        data_i = 0;
        data_valid_i = 0;

        #(100 * ClkPeriodNs);
        rst_i = 0;

        send_word(8'hAB);
        send_word(8'hBC);

        // Give enough time for the last word to be trasmitted
        #(BaudPeriodNs * 10);

        send_word(8'hCD);

        // Give enough time for the last word to be trasmitted
        #(BaudPeriodNs * 10);

        `CHECK_EQ(queue.size(), 3);
        `CHECK_EQ(queue.pop_front(), 8'hAB);
        `CHECK_EQ(queue.pop_front(), 8'hBC);
        `CHECK_EQ(queue.pop_front(), 8'hCD);

        $finish();
    end

    logic frame_in_progress = 0;
    word_t queue[$];

    initial begin
        forever begin
            word_t w = 8'b0;
            wait (!uart_o);
            frame_in_progress = 1'b1;
            #(BaudPeriodNs / 2);

            for (integer i = 0; i < WordSize; i++) begin
                #(BaudPeriodNs);
                w[WordSize-1:0] = {uart_o, w[WordSize-1:1]};
            end
            queue.push_back(w);

            // Stop bit
            #(BaudPeriodNs);

            frame_in_progress = 1'b0;
        end
    end

    property p_ack_is_valid;
        // An acknowledge is only valid if the data valid is high
        @(posedge clk_i) !(data_ack_o && !data_valid_i);
    endproperty
    `CHECK_PROPERTY(p_ack_is_valid, "ACK found when data was not valid");

    property p_uart_idle;
        @(posedge clk_i) disable iff (rst_i) (!data_valid_i && !frame_in_progress) |-> uart_o;
    endproperty
    `CHECK_PROPERTY(p_uart_idle, "Uart idle");

    property p_uart_is_defined;
        @(posedge clk_i) disable iff (rst_i) uart_o !== 1'bx;
    endproperty
    `CHECK_PROPERTY(p_uart_is_defined, "Uart value is always defined");

endmodule
