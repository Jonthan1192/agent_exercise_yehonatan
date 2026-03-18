// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "avalon_st_driver.sv"

module tb ();

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;
    localparam int unsigned READY_PERCECNTAGE   = 50;

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    // Packet variable
    byte packet[$];

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));

    // Classes declarations.
    avalon_st_driver#(.DATA_WIDTH_IN_BYTES(vif.DATA_WIDTH_IN_BYTES), .IS_MASTER(1'b1), .IS_SLAVE(1'b1)) driver = new(vif);

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
        #(10000) $finish;
    end

    // Waves dump.
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    //////////////////////////////////////////////////////////////////////////////
    // TestBench Logic
    //////////////////////////////////////////////////////////////////////////////
    // Test logic.
    initial begin
        packet = {8'hDE, 8'hED, 8'hBE, 8'hEF};
        driver.drive_master(packet);

        packet = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE};
        driver.drive_master(packet);

        packet = {8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55};
        driver.drive_master(packet);

        packet = {8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66};
        driver.drive_master(packet);

        packet = {8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77};
        driver.drive_master(packet);

        packet = {8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88};
        driver.drive_master(packet);
    end

endmodule
