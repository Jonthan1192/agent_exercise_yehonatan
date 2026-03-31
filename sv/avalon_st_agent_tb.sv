// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "avalon_st_driver.sv"
`include "avalon_st_monitor.sv"

module tb ();

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;
    localparam int unsigned MIN_MSG_SIZE_BYTES  = 1;
    localparam int unsigned MAX_MSG_SIZE_BYTES  = 20;

    // Valid and ready percentage
    localparam int unsigned READY_PERCECNTAGE   = 75;
    localparam int unsigned VALID_PERCECNTAGE   = 75;

    // Num of messages to send
    localparam int unsigned MSG_NUM             = 10;

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    // Msg variable
    byte msg[$];

    // Msg from monitor
    byte msg_from_monitor[$];

    // Represents msg_from_monitor
    string hex_str;

    // Msg size variable
    int msg_size;

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));

    // Classes declarations.
    avalon_st_driver#(
        .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
        .IS_MASTER(1'b1),
        .VALID_READY_PERCECNTAGE(VALID_PERCECNTAGE)
    ) master_driver = new(vif);

    avalon_st_driver#(
        .DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES),
        .IS_MASTER(1'b0),
        .VALID_READY_PERCECNTAGE(READY_PERCECNTAGE)
    ) slave_driver = new(vif);

    avalon_st_monitor#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) monitor = new(vif);

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////

    // Generate clock.
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Initialize reset signal.
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Timeout.
    initial begin
        #(10000) $stop;
    end

    // Waves dump.
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    //////////////////////////////////////////////////////////////////////////////
    // TestBench Logic
    //////////////////////////////////////////////////////////////////////////////
    initial begin

        @(vif.master_cb iff rst_n);

        for (int i = 0; i < MSG_NUM; i++) begin
            msg_size = $urandom_range(MIN_MSG_SIZE_BYTES, MAX_MSG_SIZE_BYTES);
            std::randomize(msg) with {
                msg.size() == msg_size;
            };
            master_driver.drive_master(msg);
        end

        #20;
        $stop;
    end

    initial begin
        wait(rst_n);
        slave_driver.drive_slave();
    end

    initial begin
        forever begin
            // Wait until a message is available
            wait (monitor.msg_queue.size() != 0);

            // Pop the first message from the queue
            msg_from_monitor = monitor.msg_queue.pop_front();

            // Print the message as a single hex string
            hex_str = "";
            foreach (msg_from_monitor[i]) begin
                hex_str = {hex_str, $sformatf("%02h", msg_from_monitor[i])};
            end

            $display("[%0t] Received message (%0d bytes): 0x%s", $time, msg_from_monitor.size(), hex_str);
        end
    end

    initial begin
        monitor.monitor_interface();
    end

endmodule
