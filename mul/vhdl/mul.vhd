-- 20180816-1600
-- Copyright (C) 2018 Laurentiu Duca
-- SPDX-License-Identifier: GPL-2.0
-----------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;
use work.common_mul.all;
-----------------------------------------------------


entity mul is
port(	clk, rst, start:	in std_logic;
		m, r:in std_logic_vector(N_BITS-1 downto 0);
		prod:out std_logic_vector((2*N_BITS)-1 downto 0);
		done: out std_logic
);
end mul;

-----------------------------------------------------

architecture mul_arch of mul is

	signal state, next_state: std_logic;
	signal a, next_prod, next_a, prod_signal: std_logic_vector((2*N_BITS-1) downto 0);
	signal raux, next_raux: std_logic_vector ((N_BITS-1) downto 0);

begin

	done <= '1' when (state = '1') else '0';
	prod <= prod_signal;

   state_reg: process(clk, rst)
   begin
		if (rst='1') then
			prod_signal <= (others => '0');
			state <= '1';
			a <= (others => '0');
			raux <= (others => '0');
		elsif (rising_edge(clk)) then
			state <= next_state;
			prod_signal <= next_prod;
			a <= next_a;
			raux <= next_raux;
		end if;
   end process;
	
	comb_logic: process(state, raux, m, r, start)
	begin
		next_a <= a;
		next_prod <= prod_signal;
		next_state <= state;
		next_raux <= raux;
		case state is
			when '0' =>
				if(raux /= std_logic_vector(to_unsigned(0, N_BITS))) then
					next_raux <= '0' & raux(N_BITS-1 downto 1);
					if(raux(0) = '1') then
						next_prod <= std_logic_vector(unsigned(prod_signal) + unsigned(a));
					end if;
					next_a <= a((2*N_BITS)-2 downto 0) & '0';
				else 
					next_state <= '1';
				end if;
			when '1' =>	
				if(start = '1') then
					next_state <= '0';
					next_a <= N_BITS_ZERO & m;
					next_prod <= (others => '0');
					next_raux <= r;
				end if;
			when others =>
				-- this is forced by the vhdl compiler
		end case;
	end process;
	
end mul_arch;
