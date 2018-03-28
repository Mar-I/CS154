-- Student name: Mariam Iqbal
-- Student ID number: 63798633

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  port (
    clk     : in std_logic;
    reset_N : in std_logic);            -- active-low signal for reset

end CPU;

architecture CPU_arch of CPU is
-- component declaration
	
	-- Datapath (from Lab 5)
-- datapath component declaration
COMPONENT datapath is
  
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

end component;
-- Datapath component specification
for all: datapath USE ENTITY work.datapath(datapath_arch)
	port map (clk, reset_N, PCUpdate, IorD, MemRead, MemWrite, IRWrite, MemtoReg, RegDst, RegWrite, ALUSrcA, ALUsrcB, ALUControl, PCSource, opcode_out, func_out, zero);

	-- Controller (you just built)
COMPONENT control is 
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
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC;
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUcontrol  : OUT ALU_opcode;
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
end component;
	--Component Specification
for all: control USE ENTITY work.control(control_arch)
	port map (clk, reset_N, op_code, funct, zero, PCUpdate, IorD, MemRead, MemWrite, IRWrite, MemtoReg, RegDst, RegWrite, ALUSrcA, ALUsrcB, ALUControl, PCSource);

-- signal declaration
SIGNAL pcw, id, mr, mw, irw, rw, alua, z : STD_LOGIC;
SIGNAL mtr, rd, alub, pcs : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL alu : ALU_opcode;
SIGNAL op, func : opcode;



BEGIN
--connecting Controller and datapath
Controller: control 
	port map (clk => clk,
		 reset_N => reset_N,
		 op_code => op,
		 funct => func,
		 zero => z,
		 PCUpdate => pcw,
		 IorD => id,
		 MemRead => mr,
		 MemWrite=> mw,
		 IRWrite => irw,
		 MemtoReg => mtr,
		 RegDst => rd,
		 RegWrite => rw,
		 ALUSrcA => alua,
		 ALUsrcB => alub,
		 ALUControl => alu,
		 PCSource => pcs);

DP: datapath
	port map (clk => clk,
		 reset_N => reset_N,
		 PCUpdate => pcw,
		 IorD => id,
		 MemRead => mr,
		 MemWrite => mw,
		 IRWrite => irw,
		 MemtoReg => mtr,
		 RegDst => rd,
		 RegWrite => rw,
		 ALUSrcA => alua,
		 ALUsrcB => alub,
		 ALUControl => alu,
		 PCSource => pcs,
		 opcode_out => op,
		 func_out => func,
		 zero => z);


end CPU_arch;
