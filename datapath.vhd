-- Student name: your name goes here
-- Student ID number: your student id # goes here

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath is
  
  port (
    clk        : in  std_logic;
    reset_N    : in  std_logic;
    
    PCUpdate   : in  std_logic;         -- write_enable of PC

    IorD       : in  std_logic;         -- Address selection for memory (PC vs. store address)
    MemRead    : in  std_logic;		-- read_enable for memory
    MemWrite   : in  std_logic;		-- write_enable for memory

    IRWrite    : in  std_logic;         -- write_enable for Instruction Register
    MemtoReg   : in  std_logic_vector(1 downto 0);  -- selects ALU or MEMORY or PC to write to register file.
    RegDst     : in  std_logic_vector(1 downto 0);  -- selects rt, rd, or "31" as destination of operation
    RegWrite   : in  std_logic;         -- Register File write-enable
    ALUSrcA    : in  std_logic;         -- selects source of A port of ALU
    ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
    
    ALUControl : in  ALU_opcode;	-- receives ALU opcode from the controller
    PCSource   : in  std_logic_vector(1 downto 0);  -- selects source of PC

    opcode_out : out opcode;		-- send opcode to controller
    func_out   : out opcode;		-- send func field to controller
    zero       : out std_logic);	-- send zero to controller (cond. branch)

end datapath;


architecture datapath_arch of datapath is
--full instruction gets executed in one clock cycle

-- ALU component declaration
COMPONENT ALU is 
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  );
end COMPONENT;

-- ALU component specification
for all: ALU USE ENTITY work.ALU(ALU_arch)
	port map (op_code => op_code, in0 => in0, in1 => in1, C => C, ALUout => ALUout, Zero => Zero);

-- Regfile component declaration
COMPONENT RegFile IS
port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in STD_LOGIC_VECTOR(4 downto 0);
        d_in                          : in STD_LOGIC_VECTOR(31 downto 0); 
        d_out_1, d_out_2              : out STD_LOGIC_VECTOR(31 downto 0)
  );
END COMPONENT;
-- Regfile Component specification
for all: RegFile USE ENTITY work.RegFile(RF_arch)
	port map (clk => clk, wr_en => wr_en, rd_addr_1 => rd_addr_1, rd_addr_2 => rd_addr_2, wr_addr => wr_addr, d_in => d_in, d_out_1 => d_out_1, d_out_2 => d_out_2);

--Mem Component declaration
Component mem IS
   PORT (MemRead	: IN std_logic;
	 MemWrite	: IN std_logic;
	 d_in		: IN   word;		 
	 address	: IN   word;
	 d_out		: OUT  word 
	 );
END Component;

--mem component specification
for all: mem USE ENTITY work.mem(mem_arch)
	port map( MemRead => MemRead, MemWrite => MemWrite, d_in => d_in, address => address, d_out => d_out);

-- signal declaration
SIGNAL alu_out: word;
SIGNAL out_temp: word;
SIGNAL rs, rt, rd : reg_addr;
Signal regIn : word;
SIGNAL regOut1, regOut2: word;
SIGNAL regA, regB: word;
SIGNAL aluin1: word;
SIGNAL aluin2: word;
SIGNAL mem_addr, mem_in, mem_out, mem_data : word;
Signal c: std_logic_vector(4 downto 0);
SIGNAL pc: word;
SIGNAL instr: word;

begin

REG: RegFile
	PORT MAP (clk => clk,
		  wr_en => RegWrite,
		  rd_addr_1 => rs,
		  rd_addr_2 => rt,
		  wr_addr => rd,
		  d_in => regIn,
		  d_out_1 => regOut1, --needed temp to write into reg A at rising edge of clock
		  d_out_2 => regOut2);  --needed temp to write into reg B at rising edge of clock

LOGIC: ALU 
	PORT MAP (op_code =>ALUControl,
        	  in0 => aluin1, 
		      in1 => aluin2,	
        	  C => c,	
        	  ALUout => out_temp, -- made a temp to hold value until written into reg at rising edge
        	  Zero => zero);

Memory: mem
	port map( MemRead => MemRead, 
		  MemWrite => MemWrite,
		  d_in => mem_in,
		  address => mem_addr,
		  d_out => mem_out);


--PC update and IF
UPDATE: PROCESS(clk, reset_N, PCUpdate)
BEGIN
--updating PC
if (reset_N = '0') then 
	pc <= x"00000000";
else
	--writing to PC
	if (clk = '1' AND clk'EVENT AND PCUpdate = '1' ) then
		case PCSource is
			WHEN "00" => pc <= out_temp;
			WHEN "01" => pc <= alu_out;
			WHEN "10" => pc <= pc(31 downto 28) & instr(25 downto 0) & "00"; --concatinating 00 to the end to sift left 2 bits
			WHEN OTHERS => NULL;
		END CASE;
	END IF;
END IF;
END PROCESS;


MEMORY_P: PROCESS(IorD, MemRead, MemWrite, pc, alu_out, regB)
BEGIN
--selecting mem address
case IorD is
	WHEN '0' => mem_addr <= pc;
	WHEN '1' => mem_addr <= alu_out;
	WHEN OTHERS => NULL;
END CASE;
--data to write waits until write is 1
	--if(MemWrite = '1') THEN
	   mem_in <= regB;
	--End If;
END PROCESS;


IR: PROCESS (clk, IRWrite)
BEGIN
--mem out goes into IR and meme data reg
If(clk = '1' AND clk'EVENT) THEN
	if(IRWrite = '1') then
		instr <= mem_out;
	END IF;
	mem_data <= mem_out;
END IF;
END PROCESS;
  

REGISTERFILE: PROCESS (instr, RegWrite, RegDst, MemtoReg, clk, alu_out, mem_data)
BEGIN
	--opcode and ALU funtion output sent to controller
	opcode_out <= instr(31 downto 26);
	func_out <= instr(5 downto 0);
	--setting all of the regfile inputs
	rs <= instr(25 downto 21);
	rt <= instr(20 downto 16);
	case RegDst is 
		WHEN "00" => rd <= instr(20 downto 16);
		WHEN "01" => rd <= instr( 15 downto 11);
		WHEN "10" => rd <= "11111";
		WHEN OTHERS => NULL;
	END CASE;
	--selecting the write data for whenever write enable is 1
	case MemtoReg is
		WHEN "00" => regIn <= alu_out;
		WHEN "01" => regIn <= mem_data;
		WHEN "10" => regIn <= pc;
		WHEN OTHERS => NULL;
	END CASE;
	
	c <= instr(10 downto 6);
	
END PROCESS;


REGS: PROCESS (clk)
BEGIN
--setting value into reg a and reg b
If(clk = '1' AND clk'EVENT) THEN
	regA <= regOut1;
	regB <= regOut2;
	alu_out <= out_temp;
END IF;
END PROCESS;


ARITH: PROCESS (ALUSrcA, ALUSrcB, ALUControl, pc, regA, regB, instr)
BEGIN
--selecting ALU input 1
CASE ALUSrcA is
	WHEN '0' => aluin1 <= pc;
	WHEN '1' => aluin1 <= regA;
	WHEN OTHERS => NULL;
END CASE;
--selecting ALU input 2
CASE ALUSrcB IS
	WHEN "00" => aluin2 <= regB;
	WHEN "01" => aluin2 <= x"00000004";
	WHEN "10" => 
		-- extend with whatever the most significant bit is
		if( instr(15) = '0') then
			aluin2 <= "0000000000000000" & instr(15 downto 0);
		else
			aluin2 <= "1111111111111111" & instr(15 downto 0);
		END IF;
	WHEN "11" => 
		-- extend with most significant bit an add 00 to end to shift
		if( instr(15) = '0') then
			aluin2 <= "00000000000000" & instr(15 downto 0) & "00";
		else
			aluin2 <= "11111111111111" & instr(15 downto 0) & "00";
		END IF;
	WHEN OTHERS => NULL;
END CASE;
END PROCESS;
end datapath_arch;
