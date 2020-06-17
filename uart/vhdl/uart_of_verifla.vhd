-- uart_of_verifla
-- date: 20180816_1740
-- author: Laurentiu Duca
-- SPDX-License-Identifier: GPL-2.0
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;

-----------------------------------------------------

entity uart_of_verifla is
port(	sys_clk, sys_rst_l: in std_logic;
		baud_clk_posedge: out std_logic;
		txd_o: out std_logic;
		wen_i: in std_logic;
		data_i: in std_logic_vector(7 downto 0);
		tre_o: out std_logic;
		rxd_i: in std_logic;
		data_o: out std_logic_vector(7 downto 0);
		rdy_o: out std_logic
);
end uart_of_verifla;

-----------------------------------------------------

architecture uart_of_verifla_arch of uart_of_verifla is

	signal sys_rst: std_logic;
	signal baud_clk_posedge_wire: std_logic;

begin	
	sys_rst <= not sys_rst_l;
	baud_clk_posedge <= baud_clk_posedge_wire;

	txd1: entity work.u_xmit_of_verifla(u_xmit_of_verifla_arch)
		port map(clk_i => sys_clk, rst_i =>sys_rst, baud_clk_posedge => baud_clk_posedge_wire, 
			data_i => data_i, wen_i => wen_i, txd_o => txd_o, tre_o => tre_o);

	rxd1: entity work.u_rec_of_verifla(u_rec_of_verifla_arch)
		port map(clk_i => sys_clk, rst_i => sys_rst, baud_clk_posedge => baud_clk_posedge_wire, 
			rxd_i => rxd_i, rdy_o => rdy_o, data_o => data_o);

	baud1: entity work.baud_of_verifla(baud_of_verifla_arch)
		port map(sys_clk => sys_clk, sys_rst_l => sys_rst_l, baud_clk_posedge => baud_clk_posedge_wire);

end uart_of_verifla_arch;
