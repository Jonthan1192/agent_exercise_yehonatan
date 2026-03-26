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

class avalon_st_driver #(int unsigned DATA_WIDTH_IN_BYTES = 4, bit IS_MASTER = 1'b1, bit IS_SLAVE = 1'b0, int unsigned READY_PERCECNTAGE = 100, int unsigned VALID_PERCECNTAGE = 100);

    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/
    virtual avalon_st_if vif;

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new (virtual avalon_st_if vif);
        this.vif = vif;

        // fork
        //     if (IS_SLAVE) begin
        //         this.drive_slave();
        //     end
        // join_none
    endfunction

    /*-------------------------------------------------------------------------------
	-- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    function logic [$clog2(DATA_WIDTH_IN_BYTES)-1:0] calc_empty(int unsigned msg_length_bytes);
        int remainder;
        remainder = msg_length_bytes % DATA_WIDTH_IN_BYTES;
        if (remainder == 0)
            return 0;
        return ((DATA_WIDTH_IN_BYTES - remainder));
    endfunction

    task drive_master(byte msg[$]);

        // Convert msg to a queue of words.
        bit [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] msg_words[$] = {>>8{msg}};

        // Loop through all the words of the msg.
        foreach (msg_words[i]) begin
            vif.CLEAR_MASTER_CB();
            vif.master_cb.valid <= 1'b1;
            vif.master_cb.sop   <= i == 0;
            vif.master_cb.data  <= msg_words[i];
            if (i == msg_words.size() - 1) begin
                vif.master_cb.eop   <= 1'b1;
                vif.master_cb.empty <= calc_empty(msg.size());
            end

            // Waiting for ready to move to the next word.
            @(this.vif.master_cb iff this.vif.master_cb.rdy);
        end

        // Prepare for next clock, in case there wont be a call to the task
        vif.CLEAR_MASTER_CB();
    endtask

    task automatic drive_slave();

        // Random value used to decide whether rdy will be asserted.
        int random_value;
        
        // This runs forever and updates rdy every clock cycle.
        forever begin
            random_value = $urandom_range(0,99);
            @(vif.slave_cb);
            vif.slave_cb.rdy <= READY_PERCECNTAGE > random_value;
        end
    endtask
endclass

`endif // __AVALON_ST_DRIVER
