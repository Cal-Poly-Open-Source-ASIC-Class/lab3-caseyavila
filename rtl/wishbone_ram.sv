`timescale 1ns/1ps

module wishbone_ram
    (input clk_i,
     `ifdef USE_POWER_PINS
     input VPWR,
     input VGND,
     `endif
     input rst_n_i,
     input pA_wb_cyc_i, pB_wb_cyc_i,
     input pA_wb_stb_i, pB_wb_stb_i,
     input [3:0] pA_wb_we_i, pB_wb_we_i,
     input [8:0] pA_wb_addr_i, pB_wb_addr_i,
     input [31:0] pA_wb_data_i, pB_wb_data_i,
     output logic [31:0] pA_wb_data_o, pB_wb_data_o,
     output logic pA_wb_ack_o, pB_wb_ack_o,
     output logic pA_wb_stall_o, pB_wb_stall_o);

    logic [3:0] we0, we1;
    logic [31:0] di0, di1;
    logic [31:0] do0, do1;
    logic [7:0] a0, a1;

    DFFRAM256x32 ram0 (
      `ifdef USE_POWER_PINS
      .VPWR(VPWR),
      .VGND(VGND),
      `endif
      .CLK(clk_i),
      .WE0(we0),
      .EN0(1'b1),
      .Di0(di0),
      .Do0(do0),
      .A0(a0)
    );

    DFFRAM256x32 ram1 (
      `ifdef USE_POWER_PINS
      .VPWR(VPWR),
      .VGND(VGND),
      `endif
      .CLK(clk_i),
      .WE0(we1),
      .EN0(1'b1),
      .Di0(di1),
      .Do0(do1),
      .A0(a1)
    );

    logic contention;
    logic turn;
    logic read_a;
    logic read_b;
    logic sel_a;
    logic sel_b;

    assign contention = pA_wb_stb_i & pB_wb_stb_i & (pA_wb_addr_i[8] == pB_wb_addr_i[8]);
    assign pA_wb_data_o = sel_a ? do1 : do0;
    assign pB_wb_data_o = sel_b ? do1 : do0;

    always @(posedge clk_i) begin
        if (~rst_n_i) begin
            turn <= 0;
        end else begin
            if (contention) begin
                turn <= ~turn;
                pA_wb_stall_o = turn;
                pB_wb_stall_o = ~turn;
            end else begin
                pA_wb_stall_o = 0;
                pB_wb_stall_o = 0;
            end

            we0 <= 0;
            we1 <= 0;

            read_a <= 0;
            if (pA_wb_cyc_i & pA_wb_stb_i & ~pA_wb_stall_o) begin
                read_a <= 1;
                sel_a <= pA_wb_addr_i[8];
                if (pA_wb_addr_i[8] == 0) begin
                    we0 <= pA_wb_we_i;
                    a0 <= pA_wb_addr_i[7:0];
                    di0 <= pA_wb_data_i;
                end else begin
                    we1 <= pA_wb_we_i;
                    a1 <= pA_wb_addr_i[7:0];
                    di1 <= pA_wb_data_i;
                end
            end

            read_b <= 0;
            if (pB_wb_cyc_i & pB_wb_stb_i & ~pB_wb_stall_o) begin
                read_b <= 1;
                sel_b <= pB_wb_addr_i[8];
                if (pB_wb_addr_i[8] == 0) begin
                    we0 <= pB_wb_we_i;
                    a0 <= pB_wb_addr_i[7:0];
                    di0 <= pB_wb_data_i;
                end else begin
                    we1 <= pB_wb_we_i;
                    a1 <= pB_wb_addr_i[7:0];
                    di1 <= pB_wb_data_i;
                end
            end

            pA_wb_ack_o <= read_a;
            pB_wb_ack_o <= read_b;
        end
    end
endmodule
