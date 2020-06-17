-----------------------------------------------------------------
-- test
-- author: Laurentiu Duca
-- SPDX-License-Identifier: GPL-2.0
-----------------------------------------------------------------

library	ieee;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity test_txd is			-- entity declaration
end test_txd;

-----------------------------------------------------------------

architecture TB of test_txd is

signal clk_i, rst_i, baud_clk_posedge, wen_i, txd_o, tre_o, rdy_o: std_logic;
signal data_i, data_o: std_logic_vector(7 downto 0);
signal stop_simulation: std_logic := '0';
signal sys_rst_l: std_logic;

begin
	sys_rst_l <= not rst_i;

	 -- labelname: entity work.entityName(architectureName)	
	unit_uart_txd: entity work.u_xmit_of_verifla(u_xmit_of_verifla_arch)
		port map(clk_i=>clk_i, rst_i=>rst_i, baud_clk_posedge=>baud_clk_posedge, 
			data_i=>data_i, wen_i=>wen_i, txd_o=>txd_o, tre_o=>tre_o);

	unit_uart_rxd: entity work.u_rec_of_verifla(u_rec_of_verifla_arch)
		port map(clk_i=>clk_i, rst_i=>rst_i, baud_clk_posedge=>baud_clk_posedge, 
			rxd_i=>txd_o, rdy_o=>rdy_o, data_o=>data_o);
			
	baud1: entity work.baud_of_verifla(baud_of_verifla_arch)
		port map(sys_clk => clk_i, sys_rst_l => sys_rst_l, baud_clk_posedge => baud_clk_posedge);
	
   process
   begin
		if stop_simulation = '0' then
			clk_i <= '1';			-- clock cycle 10 ns
			wait for 5 ns;
			clk_i <= '0';
			wait for 5 ns;
		else
			wait;
		end if;
	end process;
	
	--baud_clk_posedge <= '1';
	
   process			   
   begin
		-- not a good test
		rst_i <= '1';
		wen_i <= '0';
		data_i <= x"00";
		wait for 2000 ns;		
			
		rst_i <= '0';								 
		wait for 4000 ns;

		-- Send
		data_i <= x"61";
		wen_i <= '1';
		wait for 2000 ns;
		wen_i <= '0';
		wait for 20 ns;		
		
		wait for 200000 ns;
		-- stop simulation.
		-- assert false report "end of simulation" severity failure;
		stop_simulation <= '1';
		wait;

   end process;	 
	
end TB;

----------------------------------------------------------------------
configuration CFG_TB of test_txd is
	for TB
	end for;
end CFG_TB;
-----------------------------------------------------------------------
