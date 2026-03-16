////////////////////////////////////////////////////////////////////////////////
//
// File name    : avalon_st_driver.sv
// Project name : Agent exercise
// Author       : Yehonatna Amarin
// Date Created : 15/3/26
//
////////////////////////////////////////////////////////////////////////////////

`ifndef __AVALON_ST_DRIVER
`define __AVALON_ST_DRIVER

class avalon_st_driver;

    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new (virtual avalon_st_if vif);
	    this.vif = vif;
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
	task drive_packet(byte packet[$]);
        
        // The byte that the current word starts from.
        int current_byte = 0;

        // Used to calc empty
        int remaining;

        // Loop through all the words of the packet.
        while (current_byte < packet.size()) begin
            vif.valid <= 1;
            vif.sop   <= current_byte == 0;
            vif.eop   <= (current_byte + vif.DATA_WIDTH_IN_BYTES) >= packet.size();
            if (vif.eop) begin
                vif.data  <= packet[current_byte : $];
                remaining = packet.size() - current_byte;
                vif.empty <= vif.DATA_WIDTH_IN_BYTES - remaining;
            end else begin
                vif.data  <= packet[current_byte +: vif.DATA_WIDTH_IN_BYTES];
                vif.empty <= 0;
            end

            // Waiting for ready to move to the next word.
            while (!vif.rdy) begin
                @(posedge vif.clk);
            end

            // Increment the current byte.
            current_byte += vif.DATA_WIDTH_IN_BYTES;
        end
        vif.valid <= 0;
    endtask
	
    task drive_ready(int ready_probability);

        // Random value used to decide whether rdy will be asserted.
        int random_value;

        // Safety check.
        if (ready_probability < 0 || ready_probability > 100) begin
            $fatal("Ready probability must be in range 0 to 100!");
        end

        // This runs forever and updates rdy every clock cycle.
        forever begin
            value = $urandom_range(0,99);
            vif.rdy <= ready_probability > value;
            @(posedge clk);
        end
    endtask
endclass

`endif // __AVALON_ST_DRIVER
