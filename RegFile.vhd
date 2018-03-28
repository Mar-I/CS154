-- Student name: your name goes here
-- Student ID number: your student id # goes here
-- Student name: your partner's name goes here
-- Student ID number: your partner's student id # goes here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity RegFile is 
  port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in STD_LOGIC_VECTOR(4 downto 0);
        d_in                          : in STD_LOGIC_VECTOR(31 downto 0); 
        d_out_1, d_out_2              : out STD_LOGIC_VECTOR(31 downto 0)
  );
end RegFile;

architecture RF_arch of RegFile is
-- signal declaration
type arr is array (0 to 31) of std_logic_vector(31 downto 0);
Signal RegFile: arr;

begin

PROCESS(clk)
BEGIN
RegFile(0) <= x"00000000";
--reading(does not need to wait for rising edge)
if (wr_en = '0') then
    d_out_1 <= RegFile(TO_INTEGER(UNSIGNED(rd_addr_1)));
    d_out_2 <= RegFile(TO_INTEGER(UNSIGNED(rd_addr_2)));
END IF;
--rising edge of clock
If(clk = '1' AND clk'EVENT) THEN
	--if write enabled
	If(wr_en = '1') THEN
		--make sure not writing to reg 0
		If(TO_INTEGER(UNSIGNED(wr_addr)) /= 0) THEN
			RegFile(TO_INTEGER(UNSIGNED(wr_addr))) <= d_in;
		END IF;
	END IF;
END IF;
END PROCESS;
end RF_arch;
