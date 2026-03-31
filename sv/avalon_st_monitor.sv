////////////////////////////////////////////////////////////////////////////////
//
// File name    : avalon_st_monitor.sv
// Project name : Agent exercise
// Author       : Yehonatan Amarin
// Date Created : 29/3/26
//
////////////////////////////////////////////////////////////////////////////////

`ifndef __AVALON_ST_MONITOR
`define __AVALON_ST_MONITOR

class avalon_st_monitor #(int unsigned DATA_WIDTH_IN_BYTES = 4);

    /*-------------------------------------------------------------------------------
    -- Members.
    -------------------------------------------------------------------------------*/

    // Virtual interface to monitor
    virtual avalon_st_if vif;

    // Queue of byte queues
    byte msg_queue[$][$];

    /*-------------------------------------------------------------------------------
    -- Constructor.
    -------------------------------------------------------------------------------*/
    function new (virtual avalon_st_if vif);
        this.vif = vif;
        // fork
        //     this.monitor_interface();
        // join_none
    endfunction

    /*-------------------------------------------------------------------------------
    -- Functions and Tasks.
    -------------------------------------------------------------------------------*/
    task automatic monitor_interface();

        // Tracks whether we are currently inside a packet.
        bit inside_msg = 1'b0;

        // Hold the current word.
        byte current_word[$];

        // Hold the current message.
        byte current_msg[$];

        forever begin

            // Wait for a transaction
            @(this.vif.monitor_cb iff (this.vif.monitor_cb.valid && this.vif.monitor_cb.rdy));
            if (!inside_msg) begin
                if (!this.vif.monitor_cb.sop) begin
                    $fatal("Received message out of packet!");
                end
                if (!this.vif.monitor_cb.eop) begin
                    inside_msg = 1'b1;
                end
            end else begin
                if (this.vif.monitor_cb.sop) begin
                    $fatal("Received SOP inside a packet!");
                end
                if (this.vif.monitor_cb.eop) begin
                    inside_msg = 1'b0;
                end
            end

            // Empty field cannot appear outside of eop
            if (!this.vif.monitor_cb.eop && this.vif.monitor_cb.empty != 0 ) begin
                $fatal("Received empty without eop!");
            end

            // Empty cannot be bigger or equal to the data width.
            if (this.vif.monitor_cb.empty >= DATA_WIDTH_IN_BYTES) begin
                $fatal("Received empty too big!");
            end

            // Unpack the data to the queue, after all the checks.
            current_word = {>> {this.vif.monitor_cb.data}};

            // Remove empty bytes
            for (int i = 0; i < this.vif.monitor_cb.empty; i++) begin
                current_word.pop_back();
            end

            // Push all bytes into the back of the message queue
            foreach (current_word[i])
                current_msg.push_back(current_word[i]);

            // If the message is done push it to the messages queue.
            if (this.vif.monitor_cb.eop) begin
                this.msg_queue.push_back(current_msg);
                current_msg.delete();
            end
        end
    endtask

endclass

`endif // __AVALON_ST_MONITOR
