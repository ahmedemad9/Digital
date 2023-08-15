

package pack1;
    import uvm_pkg::*;
    //export uvm_pkg::*;
	`include "uvm_macros.svh"

    /********************************* seq item ***********************************/
    class my_sequence_item extends uvm_sequence_item;
        `uvm_object_utils(my_sequence_item)
        
        function new(string name="my_sequence_item");
            super.new(name);
        endfunction
        
        rand bit [7:0] data_in;
        rand bit [5:0] addr;
        rand bit we;
        bit [7:0] data_out;
        constraint constr1 {data_in inside {[1:199]};}
    endclass


    /********************************* sequence ***********************************/
    class my_sequence extends uvm_sequence#(my_sequence_item);
        `uvm_object_utils(my_sequence)
        
        my_sequence_item seq_item;

        function new(string name="my_sequence");
            super.new(name);
        endfunction
        
        task pre_body;
            seq_item=my_sequence_item::type_id::create("seq_item");
        endtask

        task body;
            for(int i=0;i<4;i++)
            begin
                start_item(seq_item);
                    void'(seq_item.randomize());
                finish_item(seq_item);
            end
        endtask
    endclass

    /********************************* Sequencer ***********************************/
    class my_sequencer extends uvm_sequencer#(my_sequence_item);
        `uvm_object_utils(my_sequencer)
      function new(string name="my_sequencer",uvm_component parent=null);
            super.new(name);
        endfunction
    endclass

    /********************************* Scoreboard ***********************************/
    class my_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(my_scoreboard)
        
        uvm_tlm_analysis_fifo#(my_sequence_item) my_tlm_analysis_fifo;
        uvm_analysis_export#(my_sequence_item) my_analysis_export;
        my_sequence_item seq_item;

        function new(string name="my_scoreboard",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            my_tlm_analysis_fifo=new("my_tlm_analysis_fifo", this);
            my_analysis_export=new("my_analysis_export",this);
        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            my_analysis_export.connect(my_tlm_analysis_fifo.analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            my_tlm_analysis_fifo.get_peek_export.get(seq_item);
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass


    /********************************* Subscriber ***********************************/
    class my_subscriber extends uvm_subscriber#(my_sequence_item);
        `uvm_component_utils(my_subscriber)
        
        //uvm_analysis_export#(my_sequence_item) analysis_export;

        my_sequence_item seq_item;

        function void write(T t);
        endfunction

        function new(string name="my_subscriber",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            //analysis_export=new("analysis_export",this);
        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            //my_agent.my_analysis_port.connect(my_analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass


    /********************************* Driver ***********************************/
    class my_driver extends uvm_driver#(my_sequence_item);
        `uvm_component_utils(my_driver)

        virtual interface intf local_virtual;
        my_sequence_item seq_item;
        
        function new(string name="my_driver",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db#(virtual intf)::get(this,"","vif",local_virtual))
                `uvm_fatal(get_full_name(),"Error in driver!")
        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                seq_item_port.get_next_item(seq_item);
                @(posedge local_virtual.clk)
                    local_virtual.data_in<=seq_item.data_in;
                    local_virtual.addr<=seq_item.addr;
                    local_virtual.we<=seq_item.we;
                    $display("data in=%p \naddr=%p \nwe=%p",local_virtual.data_in,local_virtual.addr,local_virtual.we);
                seq_item_port.item_done(seq_item);
            end
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass


    /********************************* Monitor ***********************************/
    class my_monitor extends uvm_monitor;
        `uvm_component_utils(my_monitor)
        
        my_sequence_item seq_item;
        uvm_analysis_port#(my_sequence_item) my_analysis_port;
        
        virtual interface intf local_virtual;
        //virtual intf vif;

        function new(string name="my_monitor",uvm_component parent=null);
            super.new(name,parent);
        endfunction


        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
           
          seq_item=my_sequence_item::type_id::create("seq_item");
          if(!uvm_config_db#(virtual intf)::get(this,"","vif",local_virtual))
                `uvm_fatal(get_full_name(),"Error in monitor!")
          
          my_analysis_port=new("my_analysis_port",this);

        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            //phase.raise_objection(this);
                my_analysis_port.write(seq_item);
            forever begin
                @(posedge local_virtual.clk)
                    seq_item.data_out<=local_virtual.data_out;
                    my_analysis_port.write(seq_item);
                    $display("  Monitor out =%p",seq_item.data_out);
            end
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass

    /********************************* Agent ***********************************/
    class my_agent extends uvm_agent;
        `uvm_component_utils(my_agent)
        
        my_driver driver;
        my_monitor monitor;
        my_sequencer ag_sequencer;
        my_sequence_item seq_item;
        uvm_analysis_port#(my_sequence_item) my_analysis_port;
        //my_sequence sequence_inst;

        virtual interface intf config_virtual;
        virtual interface intf local_virtual;

        function new(string name="my_agent",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            driver=my_driver::type_id::create("driver",this);
            monitor=my_monitor::type_id::create("monitor",this);
            ag_sequencer=my_sequencer::type_id::create("ag_sequencer");
            seq_item=my_sequence_item::type_id::create("seq_item");

            if(!uvm_config_db#(virtual intf)::get(this,"","vif",local_virtual))
                `uvm_fatal(get_full_name(),"Error in agent!")

            config_virtual=local_virtual;
            uvm_config_db#(virtual intf)::set(this,"driver","vif",config_virtual);
            uvm_config_db#(virtual intf)::set(this,"monitor","vif",config_virtual);
            
            my_analysis_port=new("my_analysis_port",this);

        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            monitor.my_analysis_port.connect(this.my_analysis_port);
            driver.seq_item_port.connect(ag_sequencer.seq_item_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass

    /********************************* Env ***********************************/
    class my_env extends uvm_env;
        `uvm_component_utils(my_env)
        
        my_agent agent;
        my_subscriber subscriber;
        my_scoreboard scoreboard;

        virtual  intf config_virtual;
        virtual  intf local_virtual;

        function new(string name="my_env",uvm_component parent=null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            agent=my_agent::type_id::create("agent",this);
            subscriber=my_subscriber::type_id::create("my_subscriber",this);
            scoreboard=my_scoreboard::type_id::create("my_scoreboard",this);
            
      	    if(!uvm_config_db#(virtual intf)::get(this,"","vif",local_virtual))
                `uvm_fatal(get_full_name(),"Error in env")
            
            config_virtual=local_virtual;            
         	 uvm_config_db#(virtual intf)::set(this,"agent","vif",config_virtual);

        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            
            agent.my_analysis_port.connect(scoreboard.my_analysis_export);
            agent.my_analysis_port.connect(subscriber.analysis_export);

        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
        endtask

        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass

    /********************************* Test ***********************************/
    class my_test extends uvm_test;
        `uvm_component_utils(my_test)

        my_env env; 
        virtual  intf config_virtual;
        virtual  intf local_virtual;
       
        my_sequence#(0,199)   sequence1;
        my_sequence#(200,399) sequence2;
        my_sequencer sequencer;
        my_sequence_item seq_item;

        function new(string name="my_test",uvm_component parent=null);
            super.new(name,parent);
          endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env=my_env::type_id::create("env",this);
            seq_item=my_sequence_item::type_id::create("seq_item");
            sequencer=my_sequencer::type_id::create("sequencer");
            sequence1=my_sequence::type_id::create("sequence1");
            sequence2=my_sequence::type_id::create("sequence2");

          if(!(uvm_config_db#(virtual intf)::get(this,"","vif",local_virtual)))
                `uvm_fatal(get_full_name(),"Error in test")
            config_virtual=local_virtual;
          uvm_config_db#(virtual intf)::set(this,"env","vif",config_virtual);
        
        endfunction 
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this);
                sequence1.start(env.agent.ag_sequencer);
                sequence2.start(env.agent.ag_sequencer);
            phase.drop_objection(this);
        endtask
    
        function void extract_phase(uvm_phase phase);
            super.extract_phase(phase);
        endfunction
    endclass
    
endpackage

interface intf;
        bit [7:0] data_in;
        bit [5:0] addr;
        bit we;
        bit clk;
        bit [7:0] data_out;

        always #1 clk=!clk;
endinterface

          
module top_module();
 
    intf intf1();
    virtual intf vif1;
    import uvm_pkg::*;
    import pack1::*;
	//`include "base/uvm_globals.svh"

    initial
    begin
        vif1=intf1;
        uvm_config_db #(virtual interface intf)::set(null,"uvm_test_top","vif",vif1);
        run_test("my_test"); 
    end

    ram DUV(
        .data(intf1.data_in),
        .addr(intf1.addr),
        .we(intf1.we),
        .clk(intf1.clk),
        .q(intf1.data_out)
    );
endmodule

