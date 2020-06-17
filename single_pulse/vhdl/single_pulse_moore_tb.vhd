-----------------------------------------------------------------
-- Booth algorithm for multiplication
-- Copyright (C) 2020 Laurentiu-Cristian Duca
-- SPDX-License-Identifier: GPL-2.0
-----------------------------------------------------------------

library	ieee;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity single_pulse_moore_tb is			-- entity declaration
end single_pulse_moore_tb;

-----------------------------------------------------------------

architecture TB of single_pulse_moore_tb is

signal T_clk: std_logic; 
signal T_rst_l:	std_logic;
signal T_ub: std_logic;
signal T_ubsing: std_logic;
signal stop_simulation: std_logic := '0';

component single_pulse_moore
port(	clk:		in std_logic;
		rst_l:		in std_logic;
		ub:			in std_logic;
		ubsing:		out std_logic
);
end component;

begin
	
    U_single_pulse_moore: single_pulse_moore port map(rst_l=>T_rst_l, clk=>T_clk, ub=>T_ub, ubsing=>T_ubsing);
	
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
	
    process			   
    begin
	T_rst_l <= '0';
	T_ub <= '0';
	wait for 20 ns;
	T_rst_l	<= '1';								 
	wait for 30 ns;
	T_ub <= '1';
	wait for 50 ns;		
	T_ub <= '0';
	wait for 50 ns;

	-- stop simulation.
	--assert false report "end of simulation" severity failure;
	stop_simulation <= '1';
	wait;

    end process;	 
	
end TB;

----------------------------------------------------------------------
configuration CFG_TB of single_pulse_moore_tb is
	for TB
	end for;
end CFG_TB;
-----------------------------------------------------------------------
