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
    logic [1:0] read_a;
    logic [1:0] read_b;
    logic [1:0] buf_read_a;
    logic [1:0] buf_read_b;
    logic stall_a;
    logic stall_b;

    assign contention = pA_wb_stb_i & pB_wb_stb_i & (pA_wb_addr_i[8] == pB_wb_addr_i[8]);

    always_comb begin
        if (contention) begin
            stall_a = turn;
            stall_b = ~turn;
        end else begin
            stall_a = 0;
            stall_b = 0;
        end
    end

    always_comb begin
        we0 = 0;
        a0 = 0;
        di0 = 0;
        we1 = 0;
        a1 = 0;
        di1 = 0;
        read_a = 0;
        read_b = 0;

        if (pA_wb_cyc_i & pA_wb_stb_i & ~pA_wb_stall_o) begin
            if (pA_wb_addr_i[8] == 0) begin
                we0 = pA_wb_we_i;
                a0 = pA_wb_addr_i[7:0];
                di0 = pA_wb_data_i;
                read_a = 2'b01;
            end else begin
                we1 = pA_wb_we_i;
                a1 = pA_wb_addr_i[7:0];
                di1 = pA_wb_data_i;
                read_a = 2'b10;
            end
        end

        if (pB_wb_cyc_i & pB_wb_stb_i & ~pB_wb_stall_o) begin
            if (pB_wb_addr_i[8] == 0) begin
                we0 = pB_wb_we_i;
                a0 = pB_wb_addr_i[7:0];
                di0 = pB_wb_data_i;
                read_b = 2'b01;
            end else begin
                we1 = pB_wb_we_i;
                a1 = pB_wb_addr_i[7:0];
                di1 = pB_wb_data_i;
                read_b = 2'b10;
            end
        end
    end

    always_latch begin
        if (buf_read_a == 2'b01) pA_wb_data_o = do0;
        if (buf_read_a == 2'b10) pA_wb_data_o = do1;
        if (buf_read_b == 2'b01) pB_wb_data_o = do0;
        if (buf_read_b == 2'b10) pB_wb_data_o = do1;
    end

    always @ (posedge clk_i) begin
        if (~rst_n_i) begin
            turn <= 0;
        end else begin
            if (contention) begin
                turn <= ~turn;
            end

            buf_read_a <= read_a;
            pA_wb_ack_o <= read_a != 2'b0;
            pA_wb_stall_o <= stall_a;

            buf_read_b <= read_b;
            pB_wb_ack_o <= read_b != 2'b0;
            pB_wb_stall_o <= stall_b;
        end
    end
endmodule
