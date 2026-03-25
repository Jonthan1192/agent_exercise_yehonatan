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
	task drive_master(byte msg[$]);
        
        // The byte that the current word starts from.
        int current_byte = 0;

        // Used to calc empty.
        int remaining;
      
      	// Prevents using previous cycle eop.
      	bit is_eop;

        // Convert msg to a queue of words.
        bit [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] msg_words[$] = {<<8{msg}};

        // Loop through all the words of the msg.
        foreach (msg_words[i]) begin
            $display("word[%0d] = %h", i, msg_words[i]);
        end

        @(vif.master_cb);

        // Loop through all the words of the msg.
        while (current_byte < msg.size()) begin
            vif.master_cb.valid <= 1'b1;
            vif.master_cb.sop   <= current_byte == 0;
            is_eop               = (current_byte + DATA_WIDTH_IN_BYTES) >= msg.size();
            vif.master_cb.eop   <= is_eop;
            if (is_eop) begin
                vif.master_cb.data  <= {>>8{msg[current_byte : $]}};
                remaining = msg.size() - current_byte;
                vif.master_cb.empty <= DATA_WIDTH_IN_BYTES - remaining;
            end else begin
                vif.master_cb.data  <= {>>8{msg[current_byte : current_byte + DATA_WIDTH_IN_BYTES - 1]}};
                vif.master_cb.empty <= 0;
            end

            // Waiting for ready to move to the next word.
            @(this.vif.master_cb iff this.vif.master_cb.rdy);

            // Increment the current byte.
            current_byte += DATA_WIDTH_IN_BYTES;
        end
        vif.master_cb.valid <= 0;
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
