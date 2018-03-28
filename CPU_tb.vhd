-- Student name: Mariam Iqbal
-- Student ID number: 63798633

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU_tb is
end CPU_tb;

architecture CPU_test of CPU_tb is
-- component declaration
	-- CPU (you just built)

COMPONENT CPU IS
	port (
    		clk     : in std_logic;
    		reset_N : in std_logic);            -- active-low signal for reset

end COMPONENT;	

-- component specification
For all: CPU USE ENTITY work.CPU(CPU_arch)
	port map (clk => clk, reset_N => reset_N);

-- signal declaration
	-- You'll need clock and reset.
SIGNAL clk_s : STD_LOGIC := '0';
SIGNAL rst_s : STD_LOGIC := '0';

begin

Test: CPU
	PORT MAP(clk => clk_s, reset_N => rst_s);

clk_s <= NOT clk_s after 20 ns;

PROCESS
BEGIN

WAIT FOR 24 ns;
rst_s <= '1';
WAIT;

END PROCESS;

end CPU_test;
