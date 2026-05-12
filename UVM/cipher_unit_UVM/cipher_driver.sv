// =============================================================================
// File        : cipher_driver.sv
// Description : UVM driver for cipher_unit.
//               Handles hard reset, key loading, data driving, and waiting
//               for Valid+CF handshake so consecutive blocks are chained
//               correctly for multi-block "file" tests.
// =============================================================================
`ifndef CIPHER_DRIVER_SV
`define CIPHER_DRIVER_SV

class cipher_driver extends uvm_driver #(cipher_transaction);
  `uvm_component_utils(cipher_driver)

  virtual cipher_unit_interface vif;

  // Broadcasts the stamped sequence item as soon as it is received from the
  // sequencer — before any driving occurs.  The scoreboard subscribes to this
  // port to get test_name / mode_str / tc_id, which are not observable on the
  // DUT interface wires.
  uvm_analysis_port #(cipher_transaction) ap_drv;

  // Number of clock cycles to wait per phase based on KL
  // (Key gen + encrypt/decrypt = 2 * duration per Table 4 of spec)
  // KL=0: 12 cyc, KL=1: 14 cyc, KL=2: 16 cyc (plus key expansion pass = same)
  localparam int WAIT_CYCLES[3] = '{12, 14, 16};

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_drv = new("ap_drv", this);
    if (!uvm_config_db #(virtual cipher_unit_interface)::get(
          this, "", "cipher_unit_interface", vif))
      `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
  endfunction

  // ---------------------------------------------------------------------------
  // Reset helpers
  // ---------------------------------------------------------------------------

  // Hard reset: clears both state (CLR) and round keys (CK)
  task hard_reset();
    @(posedge vif.CLK);
    vif.CLR <= 1'b1;
    vif.CK  <= 1'b1;
    @(posedge vif.CLK);
    vif.CLR <= 1'b0;
    vif.CK  <= 1'b0;
  endtask

  // Soft reset: clears state register only
  task soft_reset();
    @(posedge vif.CLK);
    vif.CLR <= 1'b1;
    vif.CK  <= 1'b0;
    @(posedge vif.CLK);
    vif.CLR <= 1'b0;
  endtask

  // Key reset: re-runs key expansion without touching state
  task key_reset();
    @(posedge vif.CLK);
    vif.CLR <= 1'b0;
    vif.CK  <= 1'b1;
    @(posedge vif.CLK);
    vif.CK  <= 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Apply stimulus from a transaction object
  // ---------------------------------------------------------------------------
  task apply_stimulus(cipher_transaction tr);
    // Drive control & key signals
    vif.enc_dec <= tr.enc_dec;
    vif.KL      <= tr.KL;
    vif.CLR     <= 1'b0;
    vif.CK      <= 1'b0;

    // Drive 256-bit key (8 x 32-bit words, little-endian words)
    for (int i = 0; i < 8; i++)
      vif.KEY[i] <= tr.Key[i*32 +: 32];

    // Drive 128-bit data block (4 x 32-bit words)
    vif.state_i[3] <= tr.Data[127:96];
    vif.state_i[2] <= tr.Data[95:64];
    vif.state_i[1] <= tr.Data[63:32];
    vif.state_i[0] <= tr.Data[31:0];
  endtask

  // ---------------------------------------------------------------------------
  // Wait for the DUT to signal it needs input (CF high) or produces output
  // (Valid high). Returns when the DUT asserts Valid.
  // ---------------------------------------------------------------------------
  task wait_for_valid(bit [1:0] kl);
    int cyc = (kl == 2'b00) ? WAIT_CYCLES[0] :
              (kl == 2'b01) ? WAIT_CYCLES[1] : WAIT_CYCLES[2];
    repeat(cyc) @(posedge vif.CLK);
  endtask

  // ---------------------------------------------------------------------------
  // Run phase — consume transactions from the sequencer
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    cipher_transaction tr;
    super.run_phase(phase);

    // Initialise interface to safe defaults
    vif.driver_started <= 1'b0;
    vif.input_taken    <= 1'b0;
    vif.CLR <= 1'b0;
    vif.CK  <= 1'b0;
    vif.enc_dec <= 1'b1;
    vif.KL      <= 2'b00;
    foreach (vif.KEY[i])   vif.KEY[i] <= 32'h0;
    foreach (vif.state_i[i]) vif.state_i[i] <= 32'h0;

    forever begin
      seq_item_port.get_next_item(tr);

      // Broadcast stamped item immediately so scoreboard can record identity
      ap_drv.write(tr);

      vif.driver_started <= 1'b1;

      // --- Apply the reset type requested by this transaction ---
      // 0=hard (CLR+CK), 1=soft (CLR only), 2=key (CK only then CLR to clear state)
      case (tr.reset_type)
        2'd1: soft_reset();
        2'd2: begin
          // Key reset: pulse CK to re-run key expansion, then CLR to flush
          // the state register so the DUT starts from a clean state.
          // This matches the intended HW usage of the key-reset signal.
          key_reset();
          soft_reset();
        end
        default: hard_reset();
      endcase

      // --- Apply stimulus (key, data, mode) ---
      apply_stimulus(tr);

      // Signal monitor that an input is being presented
      @(posedge vif.CLK);
      vif.input_taken <= 1'b1;
      @(posedge vif.CLK);
      vif.input_taken <= 1'b0;

      // --- Wait for key expansion + first encryption/decryption pass ---
      wait_for_valid(tr.KL);

      // --- Wait for second pass (CF re-assertion for streaming) ---
      wait_for_valid(tr.KL);

      // --- Hard reset after every transaction to leave DUT in clean state ---
      hard_reset();

      seq_item_port.item_done();
    end
  endtask

endclass : cipher_driver

`endif // CIPHER_DRIVER_SV