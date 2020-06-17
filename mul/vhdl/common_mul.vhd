
-- SPDX-License-Identifier: GPL-2.0
-- Copyright (C) 2020, L-C. Duca
-----------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-----------------------------------------------------


package common_mul is
constant N_BITS: integer :=4;
constant PROD_BITS: integer :=(2*N_BITS); 
constant N_BITS_ZERO: std_logic_vector((N_BITS-1) downto 0) := (others => '0');
end common_mul;
