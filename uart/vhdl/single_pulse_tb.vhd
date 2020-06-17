-----------------------------------------------------------------
-- test
-- author: Laurentiu Duca
-- SPDX-License-Identifier: GPL-2.0
-----------------------------------------------------------------

library	ieee;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity single_pulse_tb is			-- entity declaration
end single_pulse_tb;

-----------------------------------------------------------------

architecture TB of single_pulse_tb is

signal T_clk, T_reset, T_baud_clk_posedge: std_logic;
signal T_ub: std_logic; 
signal T_ubsing: std_logic;
signal stop_simulation: std_logic := '0';

begin
	 -- labelname: entity work.entityName(architectureName)	
    unit_single_pulse: entity work.single_pulse(single_pulse_arch) 
	 port map(reset=>T_reset, clk=>T_clk, baud_clk_posedge=>T_baud_clk_posedge,
		ub=>T_ub, ubsing=>T_ubsing);
	
   process
   begin
		if stop_simulation = '0' then
			T_clk <= '1';			-- clock cycle 10 ns
			wait for 5 ns;
			T_clk <= '0';
			wait for 5 ns;
		else
			wait;
		end if;
	end process;
	
	T_baud_clk_posedge <= '1';
	
   process			   
   begin
		T_reset <= '0';
		T_ub <= '1';
		wait for 20 ns;		
			
		T_reset <= '1';								 
		wait for 40 ns;
		
		T_ub <= '0';
		wait for 40 ns;
		T_ub <= '1';
		
		wait for 200 ns;
		-- stop simulation.
		-- assert false report "end of simulation" severity failure;
		stop_simulation <= '1';
		wait;

   end process;	 
	
end TB;

----------------------------------------------------------------------
configuration CFG_TB of single_pulse_tb is
	for TB
	end for;
end CFG_TB;
-----------------------------------------------------------------------
