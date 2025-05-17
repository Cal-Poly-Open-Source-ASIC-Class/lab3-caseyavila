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
    logic stall_a;
    logic stall_b;
    logic [1:0] read_a;
    logic [1:0] read_b;
    logic turn;

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

    `define send(we, data_i, a, read) \
        if (a[8] == 0) begin \
            we0 <= we; \
            di0 <= data_i; \
            a0 <= a[7:0]; \
            read <= 2'b01; \
        end else begin \
            we1 <= we; \
            di1 <= data_i; \
            a1 <= a[7:0]; \
            read <= 2'b10; \
        end

    `define recv(ack, read, data_o) \
        ack <= 1; \
        read <= 2'b0; \
        if (read == 2'b01) begin \
            data_o <= do0; \
        end else begin \
            data_o <= do1; \
        end

    always @ (negedge clk_i) begin
        if (~rst_n_i) begin
            read_a <= 2'b0;
            read_b <= 2'b0;
            turn <= 0;
        end

        if (contention) begin
            turn <= ~turn;
        end

        if (read_a != 2'b0) begin
            `recv(pA_wb_ack_o, read_a, pA_wb_data_o);
        end else begin
            pA_wb_ack_o <= 0;
        end

        if (read_b != 2'b0) begin
            `recv(pB_wb_ack_o, read_b, pB_wb_data_o);
        end else begin
            pB_wb_ack_o <= 0;
        end

        if (pA_wb_cyc_i & pA_wb_stb_i & ~stall_a) begin
            `send(pA_wb_we_i, pA_wb_data_i, pA_wb_addr_i, read_a);
        end
        if (pB_wb_cyc_i & pB_wb_stb_i & ~stall_b) begin
            `send(pB_wb_we_i, pB_wb_data_i, pB_wb_addr_i, read_b);
        end

        pA_wb_stall_o <= stall_a;
        pB_wb_stall_o <= stall_b;

    end
endmodule
