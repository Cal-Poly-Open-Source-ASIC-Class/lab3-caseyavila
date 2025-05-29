`timescale 1ns/1ps

module tb_wishbone_ram;

// Declare test variables
logic clk_i;
logic rst_n_i;
logic pA_wb_cyc_i, pB_wb_cyc_i;
logic pA_wb_stb_i, pB_wb_stb_i;
logic [3:0] pA_wb_we_i, pB_wb_we_i;
logic [8:0] pA_wb_addr_i, pB_wb_addr_i;
logic [31:0] pA_wb_data_i, pB_wb_data_i;
logic [31:0] pA_wb_data_o, pB_wb_data_o;
logic pA_wb_ack_o, pB_wb_ack_o;
logic pA_wb_stall_o, pB_wb_stall_o;

`ifdef USE_POWER_PINS
    wire VPWR;
    wire VGND;
    assign VPWR=1;
    assign VGND=0;
`endif


// Instantiate Design 
wishbone_ram wb (.*);

// Sample to drive clock
localparam CLK_PERIOD = 10;
always begin
    #(CLK_PERIOD/2) 
    clk_i <= ~clk_i;
end

// Necessary to create Waveform
initial begin
    // Name as needed
    $dumpfile("tb_wishbone_ram.vcd");
    $dumpvars(2, tb_wishbone_ram);
end

task init();
    pA_wb_cyc_i = 0;
    pA_wb_stb_i = 0;
    pA_wb_addr_i = 0;
    pA_wb_we_i = 4'b0;
    pA_wb_data_i = 32'b0;

    pB_wb_cyc_i = 0;
    pB_wb_stb_i = 0;
    pB_wb_addr_i = 0;
    pB_wb_we_i = 4'b0;
    pB_wb_data_i = 32'b0;
endtask

task use_mem(input logic write,
             input logic [8:0] a_addr,
             input logic [8:0] b_addr,
             input int delay);
    pA_wb_cyc_i = 1;
    pA_wb_stb_i = 1;

    pB_wb_cyc_i = 1;
    pB_wb_stb_i = 1;

    for (int i = 0; i < 5; i++) begin
        if (write) begin
            pA_wb_we_i = 4'b1111;
            pA_wb_data_i = 32'hBEEF0000 + i;

            pB_wb_we_i = 4'b1111;
            pB_wb_data_i = 32'hCAFE0000 + i;
        end else begin
            pA_wb_we_i = 4'b0;
            pA_wb_data_i = 32'b0;

            pB_wb_we_i = 4'b0;
            pB_wb_data_i = 32'b0;
        end

        pA_wb_addr_i = a_addr + i[8:0];
        pB_wb_addr_i = b_addr + i[8:0];

        for (int d = 0; d < delay; d++)
            #10;
    end
    
    pA_wb_stb_i = 0;
    pA_wb_we_i = 4'b0;

    pB_wb_stb_i = 0;
    pB_wb_we_i = 4'b0;

    #10;
    pA_wb_cyc_i = 0;
    pB_wb_cyc_i = 0;
endtask

always begin
    // Test Goes Here
    clk_i = 1;
    rst_n_i = 0;

    init();

    #20;
    rst_n_i = 1;

    use_mem(1, 9'h000, 9'h100, 1);
    #10;
    use_mem(0, 9'h100, 9'h000, 1);

    #20;

    use_mem(1, 9'h010, 9'h020, 2);
    #10;
    use_mem(0, 9'h020, 9'h010, 2);

    #500;


    // Make sure to call finish so test exits
    $finish();
end

endmodule
