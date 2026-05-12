`timescale 1ns/1ns
// =============================================================================
// File        : interface.sv
// Description : SystemVerilog interface for the cipher_unit DUT
// =============================================================================
`ifndef CIPHER_INTERFACE_SV
`define CIPHER_INTERFACE_SV

interface cipher_unit_interface (input CLK);

  logic        CLR;
  logic        CK;
  logic [31:0] KEY    [7:0];
  logic [1:0]  KL;
  logic        enc_dec;
  logic [31:0] state_i[3:0];
  logic [31:0] state_o[3:0];
  logic        Valid;
  logic        CF;

  // Handshake helpers used by driver/monitor
  bit input_taken;
  bit driver_started;

  modport tb (
    input  CLK,
    output CLR, CK, KEY, KL, enc_dec, state_i,
    input  state_o, Valid, CF
  );

  modport dut (
    input  CLK, CLR, CK, KEY, KL, enc_dec, state_i,
    output state_o, Valid, CF
  );

endinterface : cipher_unit_interface

`endif // CIPHER_INTERFACE_SV
