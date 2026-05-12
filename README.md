# AES ASIC implementation

This project was created to be used a custom AES ASIC, capable of encrypting or decrypting a plaintext/ciphertext on all modes of operations or all key lengths as detailed by FIPS 197. No external modules or licences were used in this project, all RTL files were designed based on available documentation on AES. This project was UVM verified and implemented as a physical design as well.

## Files overview
### RTL

The RTL folder contains all RTL files and testbenches in their respective folders, three example mem files are also included.

### UVM

As UVM was done on EDA playground using Synopsys VCS 2025.6 the design.sv and testbench.sv files need to be copy pasted into their respective pages, while the UVM files are simply dragged and dropped into the LEFT pannel and the RTL files to the RIGHT pannel. 

### PD

A zip file of the PD reports is included to make it easier to download.

## Dependencies
### RTL testbench

The file handles for each meme file in test (1) of top_tb.sv will need to be updated to match the file location of each mem file on your local device.

### UVM

EDA playground requires the following options to run properly

Run options : +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM

compile options (for reference.c based testbenches): -timescale=1ns/1ns +vcs+flush+all -sverilog -CFLAGS "-DVCS" reference.c

compile options (for other testbenches): -timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog

## RTL testbench use

The RTL testbench has 2 types of tests, one for debugging a specific plaintext against all modes and key lengths and another to encrypt and decrypt a plaintext mem file.


