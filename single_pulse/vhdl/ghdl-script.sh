#!/bin/bash
set -x
ghdl --clean
rm *.cf *.vcd *.ghw
echo $1
set -e
ghdl -a $1.vhd $1_tb.vhd
ghdl -e $1_tb
ghdl -r $1_tb --vcd=$1.vcd
gtkwave $1.vcd $1.vcd.savefile &
#ghdl -r $1_tb --wave=$1.ghw
#gtkwave $1.ghw $1.ghw.savefile

