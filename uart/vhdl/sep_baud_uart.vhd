-- sep_baud_uart
-- SPDX-License-Identifier: GPL-2.0
-- Copyright (C) 2020, L-C. Duca
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;

-----------------------------------------------------

entity sep_baud_uart is
port(	sys_clk, reset: in std_logic;
		txd_o: out std_logic;
		rxd_i: in std_logic;
		char_leds: out std_logic_vector(7 downto 0)
);
end sep_baud_uart;

-----------------------------------------------------

architecture sep_baud_uart_arch of sep_baud_uart is

    -- define the states of FSM model
   signal sys_rst_l: std_logic;
	signal data_i, data_o: std_logic_vector(7 downto 0);
	signal tre_o, wen_i, rdy_o, baud_clk_posedge: std_logic;

begin
	sys_rst_l <= not(reset);

	iUART: entity work.uart_of_verifla(uart_of_verifla_arch)
		port map(sys_clk, sys_rst_l, baud_clk_posedge,
				-- Transmitter
				txd_o,
				wen_i,
				data_i,
				tre_o,
				-- Receiver
				rxd_i,
				data_o,
				rdy_o		
		);
		
	sp1: entity work.single_pulse(single_pulse_arch)
		port map(sys_clk, sys_rst_l, baud_clk_posedge, rdy_o, wen_i);
	
	char_leds <= data_i;
	p1: process(sys_clk, sys_rst_l)
	begin
		if(sys_rst_l='0') then
			data_i <= x"6E";
		elsif(rising_edge(sys_clk)) then
			--data_i <= data_o;
			data_i <= std_logic_vector(unsigned(data_o)+x"1");
		end if;
	end process;

end sep_baud_uart_arch;
