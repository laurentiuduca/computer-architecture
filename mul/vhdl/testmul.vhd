--------------------------------------------------------------------------------
-- 20180816-1600
-- Copyright (C) 2018 Laurentiu Duca
-- SPDX-License-Identifier: GPL-2.0
--------------------------------------------------------------------------------
LIBRARY ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use ieee.std_logic_arith.all;  
--use ieee.std_logic_unsigned.all;
use work.common_mul.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY testmul IS
END testmul;
 
ARCHITECTURE behavior OF testmul IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mul
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         start : IN  std_logic;
         m : IN  std_logic_vector((N_BITS-1) downto 0);
         r : IN  std_logic_vector((N_BITS-1) downto 0);
         prod : OUT  std_logic_vector(((2*N_BITS)-1) downto 0);
         done : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal start : std_logic := '0';
   signal m : std_logic_vector((N_BITS-1) downto 0) := (others => '0');
   signal r : std_logic_vector((N_BITS-1) downto 0) := (others => '0');

 	--Outputs
   signal prod : std_logic_vector(((2*N_BITS)-1) downto 0);
   signal done : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mul PORT MAP (
          clk => clk, rst => rst, start => start,
          m => m, r => r, prod => prod,
          done => done);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin
		m <= std_logic_vector(to_unsigned(5, N_BITS));
		r <= std_logic_vector(to_unsigned(6, N_BITS));
		rst <= '1';
      wait for clk_period*2;

      -- insert stimulus here 
		rst <= '0';
		wait for clk_period;
		start <= '1';
      wait for clk_period*2;
		start <= '0';
      wait;
   end process;

END;
