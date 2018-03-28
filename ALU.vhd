-- Student name: Mariam Iqbal
-- Student ID number: 63798633

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use work.Glob_dcls.all;

entity ALU is 
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  );
end ALU;

architecture ALU_arch of ALU is
-- signal declaration
SIGNAL temp : word;

begin
Logic: PROCESS (op_code,temp, in0, in1)
BEGIN
--initializing Zero to 0
--Zero <= '0';
CASE op_code is 
	WHEN "000" =>--ADD,
		--temp <= STD_LOGIC_VECTOR(UNSIGNED(in0) + UNSIGNED(in1));
		temp <= in0 + in1;
	WHEN "001" => --SUB
		temp <= in0 - in1;
	WHEN "010" => --Shift left logical
		temp <= SHL(in0, C);
	WHEN "011" => --Shift right logical
		temp <= SHR(in0, C);
	WHEN "100" => --AND
		temp <= in0 AND in1;
	WHEN "101" =>--OR
		temp <= in0 OR in1;
	WHEN "110" => --XOR
		temp <= in0 XOR in1;
	WHEN "111" => --NOR
		temp <= in0 NOR in1;
	WHEN others => --DO NOTHING
		NULL;
END CASE;
ALUout <= temp;
--setting Zero to 1 if ALUout is 0
IF( temp = 0) THEN
		Zero <= '1';
	ELSE
		Zero <= '0';
	END IF;
END PROCESS;

--outReg: PROCESS(clk)
--BEGIN
--If(clk = '1' AND clk'EVENT) THEN
--	ALUout <= temp;
--	IF( ALUout = 0) THEN
--		zero <= '1';
--	ELSE
--		zero <= '0';
--	END IF;
--END IF;
--END PROCESS;

end ALU_arch;
