echo %1
del *.cf *.vcd *.ghw
c:\ghdl\bin\ghdl.exe --clean
c:\ghdl\bin\ghdl.exe -a %1.vhd %1_tb.vhd
c:\ghdl\bin\ghdl.exe -e %1_tb
c:\ghdl\bin\ghdl.exe -r %1_tb --vcd=%1_tb.vcd
c:\iverilog\gtkwave\bin\gtkwave.exe %1_tb.vcd %1.vcd.savefile
--c:\ghdl\bin\ghdl.exe -r %1_tb --wave=%1.ghw
--c:\iverilog\gtkwave\bin\gtkwave.exe %1.ghw %1.ghw.savefile
