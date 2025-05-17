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
    $dumpvars(0);
end

initial begin
    // Test Goes Here
    clk_i = 0;
    rst_n_i = 1;

    #10;
    rst_n_i = 0;

    #10;
    pA_wb_cyc_i = 1;
    pA_wb_stb_i = 1;
    pA_wb_addr_i = 0;
    pA_wb_we_i = 4'b1111;
    pA_wb_data_i = 32'hffff;

    pB_wb_cyc_i = 1;
    pB_wb_stb_i = 1;
    pB_wb_addr_i = 9'b100000001;
    pB_wb_we_i = 4'b1111;
    pB_wb_data_i = 32'hdddd;

    #60;
    pB_wb_addr_i = 9'b000000001;
    pB_wb_we_i = 4'b0000;

    //#10;
    //pB_wb_cyc_i = 0;
    //pB_wb_stb_i = 0;

    #1000;

    // Make sure to call finish so test exits
    $finish();
end

endmodule
