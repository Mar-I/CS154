-- Student name: Mariam Iqbal
-- your student id # goes here: 63798633

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity control is 
   port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 
        
        op_code      : IN opcode;     -- declare type for the 6 most significant bits of IR
        funct       : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC;
        
     	PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     	IorD        : OUT STD_LOGIC;
     	MemRead     : OUT STD_LOGIC;
     	MemWrite    : OUT STD_LOGIC;

     	IRWrite     : OUT STD_LOGIC;
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL (000011)
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC;
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUcontrol  : OUT ALU_opcode;
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
end control;

architecture control_arch of control is

-- signal declaration
TYPE state IS (F, D, LS, L2, L3, S2, R1, R2, I1, I2, BE, BN, J);
SIGNAL curr, nxt: state;

TYPE operation IS (L, S, R, I, EQ, NEQ, JMP);
SIGNAL op: operation;

SIGNAL ALUtemp: ALU_opcode;

begin

--Process for signal assignments
PROCESS(curr, op_code, ALUtemp, zero, funct)
BEGIN
CASE op_code IS
	WHEN "100011" => op <= L;	
	WHEN "101011" => op <= S;
	WHEN "000000" => op <= R;
		CASE funct IS
			WHEN "100000" => ALUtemp <= "000";	--ADD
                    WHEN "100100" => ALUtemp <= "100";    --AND
                    WHEN "100010" => ALUtemp <= "001";    --SUB
                    WHEN "100101" => ALUtemp <= "101";    --OR
                    WHEN "100110" => ALUtemp <= "110";    --XOR
                    WHEN "100111" => ALUtemp <= "111";    --NOR
                    WHEN "000000" => ALUtemp <= "010";    --SLL
                    WHEN "000010" => ALUtemp <= "011";    --SLR
                    WHEN OTHERS => NULL;
		END CASE;
	WHEN "001000" => op <= I;	--ADD IMMEDIATE
		ALUtemp <= "000";
	WHEN "001100" => op <= I;	--AND IMMEDIATE
		ALUtemp <= "100";
	WHEN "001101" => op <= I;	-- OR IMMEDIATE
		ALUtemp <= "101";
	WHEN "000100" => op <= EQ;
	WHEN "000101" => op <= NEQ;
	WHEN "000010" => op <= JMP;
	WHEN OTHERS => NULL;
END CASE;

--Setting all of the signals based upon the current state
CASE curr IS
	WHEN F => PCUpdate <= '1' AFTER 1ns;
	WHEN BE => PCUpdate <= (zero AND '1') AFTER 1ns;
	WHEN BN => PCUpdate <= (NOT(zero) AND '1') AFTER 1ns;
	WHEN J => PCUpdate <= '1' AFTER 1ns;
	WHEN OTHERS => PCUpdate <= '0';
END CASE;

CASE curr IS
	WHEN L2 => IorD <= '1';
	WHEN S2 => IorD <= '1';
	WHEN OTHERS => IorD <= '0';
END CASE;

CASE curr IS
	WHEN F => MemRead <= '1' After 1ns;
	WHEN L2 => MemRead <= '1' After 1 ns;
	WHEN OTHERS => MemRead <= '0';
END CASE;

CASE curr IS
	WHEN S2 => MemWrite <= '1' After 1 ns;
	WHEN OTHERS => MemWrite <= '0' After 1 ns;
END CASE;

CASE curr IS
	WHEN F => IRWrite  <= '1';
	WHEN OTHERS => IRWrite <= '0';
END CASE;

CASE curr IS
	WHEN L3 => MemtoReg <= "01";
	WHEN OTHERS => MemtoReg <= "00";
END CASE;

CASE curr IS
	WHEN R2 => RegDst <= "01";
	--WHEN I2 => RegDst <= "00"
	WHEN OTHERS => RegDst <= "00";
END CASE;

CASE curr IS
	WHEN L3 => RegWrite <= '1';
	WHEN R2 => RegWrite <= '1';
	WHEN I2 => RegWrite <= '1';
	WHEN OTHERS => RegWrite <= '0';
END CASE;

CASE curr IS
	WHEN BE => ALUSrcA <= '1';
	WHEN BN => ALUSrcA <= '1';
	WHEN I1 => ALUSrcA <= '1';
	WHEN R1 => ALUSrcA <= '1';
	WHEN LS => ALUSrcA <= '1';
	WHEN OTHERS => ALUSrcA <= '0';
END CASE;

CASE curr IS
	WHEN F => ALUSrcB <= "01";
	WHEN D => ALUSrcB <= "11";
	WHEN LS => ALUSrcB <= "10";
	WHEN I1 => ALUSrcB <= "10";
	WHEN OTHERS => ALUSrcB <= "00";
END CASE;

CASE curr IS
	WHEN BE => 
	  -- IF(zero = '0') then
	       PCSource <= "01";
	  -- ELSE
	    --   PCSource <= "00";
	  -- END IF;
	WHEN BN => 
	  -- IF(zero = '1') then
           PCSource <= "01";
      -- ELSE
        --   PCSource <= "00";
      -- END IF;
	WHEN J => PCSource <= "10";
	WHEN OTHERS => PCSource <= "00";
END CASE;

CASE curr IS 
    WHEN R1 => ALUControl <= ALUtemp;
    WHEN I1 => ALUControl <= ALUtemp;
    WHEN BE => ALUControl <= "001";
    WHEN BN => ALUControl <= "001";
    WHEN OTHERS => ALUControl <= "000";
END CASE;

END PROCESS;

-- Process to assign next state
PROCESS(clk, curr, nxt)
BEGIN
CASE curr IS
	WHEN F => nxt <= D;
	WHEN D =>
		CASE op IS
			WHEN L => nxt <= LS After 1 ns;
			WHEN S => nxt <= LS After 1 ns;
			WHEN R => nxt <= R1 After 1 ns;
			WHEN I => nxt <= I1 After 1 ns;
			WHEN EQ => nxt <= BE After 1 ns;
			WHEN NEQ => nxt <= BN After 1 ns;
			WHEN JMP => nxt <= J After 1 ns;
		END CASE;
	WHEN LS =>
		CASE op IS
			WHEN L => nxt <= L2 After 1 ns;
			WHEN S => nxt <= S2 After 1 ns;
			WHEN OTHERS => NULL;
		END CASE;
	WHEN L2 => nxt <= L3 After 1 ns;
	WHEN L3 => nxt <= F After 1 ns;
	WHEN S2 => nxt <= F After 1 ns;
	WHEN R1 => nxt <= R2 After 1 ns;
	WHEN R2 => nxt <= F After 1 ns;
	WHEN I1 => nxt <= I2 After 1 ns;
	WHEN I2 => nxt <= F After 1 ns;
	WHEN BE => nxt <= F After 1 ns;
	WHEN BN => nxt <= F After 1 ns;
	WHEN J => nxt <= F After 1 ns;
END CASE;
END PROCESS;

--D flip flop register
PROCESS(clk, reset_N)
BEGIN

if(reset_N = '0') then
	curr <= F;
elsif (clk'EVENT AND clk = '1') then
	curr <= nxt;
END if;

END PROCESS;
end control_arch;

