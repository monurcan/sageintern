library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;

entity K_QUADRAM is
    Generic(
           RAM_WIDTH		: integer range 1 to 256  := 32;
           RAM_DEPTH        : integer range 1 to 65536:= 16;
           INIT_FILE        : string                  := "All zeros"; 
           Write_Mode		: integer range 0 to 2    := 0;

           Enable_Port_A    : boolean                 := TRUE;


           Enable_Port_B    : boolean                 := TRUE;


           Enable_Port_C    : boolean                 := TRUE;


           Enable_Port_D    : boolean                 := TRUE
);
    Port ( CLK_A 			: in STD_LOGIC;
    
		   RST_A 			: in STD_LOGIC;
           RST_B 			: in STD_LOGIC;
           RST_C 			: in STD_LOGIC;
           RST_D 			: in STD_LOGIC;
		   EN_A 			: in STD_LOGIC;
           EN_B 			: in STD_LOGIC;
           EN_C 			: in STD_LOGIC;
           EN_D 			: in STD_LOGIC;
           ADDR_A 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           ADDR_B 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           ADDR_C 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           ADDR_D 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           DATA_A 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);   
		   DATA_B 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0); 		   
		   DATA_C 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0); 		   
		   DATA_D			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0); 		   
           WR_EN_A 			: in STD_LOGIC;
		   WR_EN_B 			: in STD_LOGIC;
		   WR_EN_C 			: in STD_LOGIC;
		   WR_EN_D 			: in STD_LOGIC;
		   DOUT_A 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);
           DOUT_B 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);   
           DOUT_C 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);   
           DOUT_D 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0));   
end K_QUADRAM;

architecture RTL of K_QUADRAM is

type t_ram is array (0 to RAM_DEPTH -1) of std_logic_vector(RAM_WIDTH-1 downto 0);

	function initramfromfile (
	ramfilename : in string; 
	r_width 	: in integer; 
	r_depth 	: in integer) return t_ram is
	
	file ramfile			: text is in ramfilename;
	variable v_ramfileline 	: line;
	variable v_ram_name		: t_ram;
	variable v_bitvec 		: bit_vector(r_width-1 downto 0);
	begin
		for v_i in 0 to r_depth - 1 loop
			readline (ramfile, v_ramfileline);
			read (v_ramfileline, v_bitvec);
			v_ram_name(v_i) := to_stdlogicvector(v_bitvec);
		end loop;
		return v_ram_name;
	end function;
	
	
	function init_from_file_or_zeroes(
	ramfile 	: in string; 
	r_width 	: in integer; 
	r_depth 	: in integer) return t_ram is
	
	variable v_ram_name_0	: t_ram;
    begin
        
        if ramfile = "All zeros" then
            v_ram_name_0 := (others => (others => '0'));            
        else
            v_ram_name_0 := InitRamFromFile(ramfile, r_width, r_depth) ;
        end if;
		return v_ram_name_0;
    end;

signal DP_RAM           : t_ram
						:= init_from_file_or_zeroes(INIT_FILE, RAM_WIDTH, RAM_DEPTH);
signal Ram_Data_A       : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Ram_Data_B       : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Ram_Data_C       : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Ram_Data_D       : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Enable_inside_A  : STD_LOGIC := '1';
signal Enable_inside_B  : STD_LOGIC := '1';
signal Enable_inside_C  : STD_LOGIC := '1';
signal Enable_inside_D  : STD_LOGIC := '1';

begin

if_NE_A: if(Enable_Port_A = FALSE) generate     
    Enable_inside_A <= '1';
end generate if_NE_A;
if_E_A: if(Enable_Port_A = TRUE) generate      
    Enable_inside_A <= EN_A;
end generate if_E_A;

if_NE_B: if(Enable_Port_B = FALSE) generate     
    Enable_inside_B <= '1';
end generate if_NE_B;
if_E_B: if(Enable_Port_B = TRUE) generate      
    Enable_inside_B <= EN_B;
end generate if_E_B;

if_NE_C: if(Enable_Port_C = FALSE) generate     
    Enable_inside_C <= '1';
end generate if_NE_C;
if_E_C: if(Enable_Port_C = TRUE) generate      
    Enable_inside_C <= EN_C;
end generate if_E_C;

if_NE_D: if(Enable_Port_D = FALSE) generate     
    Enable_inside_D <= '1';
end generate if_NE_D;
if_E_D: if(Enable_Port_D = TRUE) generate      
    Enable_inside_D <= EN_D;
end generate if_E_D;


if_Mode_0:if(Write_Mode = 0) generate
    
    pr_clk_1:process(CLK_A)										
    begin
	if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                else
                    Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                end if;
            end if;


            if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;


            if(Enable_inside_C = '1') then
                if(WR_EN_C = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_C))) <= DATA_C;
                else
                    Ram_Data_C <= DP_RAM(to_integer(unsigned(ADDR_C)));
                end if;
            end if;


            if(Enable_inside_D = '1') then
                if(WR_EN_D = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_D))) <= DATA_D;
                else
                    Ram_Data_D <= DP_RAM(to_integer(unsigned(ADDR_D)));
                end if;
            end if;
        end if;
    end process pr_clk_1;
    
end generate;

if_Mode_1:if(Write_Mode = 1) generate
    

    pr_clk_1_1:process(CLK_A)										
    begin
	 if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                end if;
            end if;

            if(Enable_inside_B = '1') then
                Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                end if;
            end if;
  
          if(Enable_inside_C = '1') then
                Ram_Data_C <= DP_RAM(to_integer(unsigned(ADDR_C)));
                if(WR_EN_C = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_C))) <= DATA_C;
                end if;
            end if;
       
	     if(Enable_inside_D = '1') then
                Ram_Data_D <= DP_RAM(to_integer(unsigned(ADDR_D)));
                if(WR_EN_D = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_D))) <= DATA_D;
                end if;
            end if;
        end if;
    end process pr_clk_1_1;

    
end generate;

if_Mode_2:if(Write_Mode = 2) generate
    

    pr_clk_1_2:process(CLK_A)										
    begin
	    if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                    Ram_Data_A <= DATA_A;
                else
                    Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                end if;
            end if;
           if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                    Ram_Data_B <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;
            if(Enable_inside_C = '1') then
                if(WR_EN_C = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_C))) <= DATA_C;
                    Ram_Data_C <= DATA_C;
                else
                    Ram_Data_C <= DP_RAM(to_integer(unsigned(ADDR_C)));
                end if;
            end if;
         if(Enable_inside_D = '1') then
                if(WR_EN_D = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_D))) <= DATA_D;
                    Ram_Data_D <= DATA_D;
                else
                    Ram_Data_D <= DP_RAM(to_integer(unsigned(ADDR_D)));
                end if;
            end if;
        end if;
    end process pr_clk_1_2;

    
end generate;

        DOUT_A <= Ram_Data_A;
        DOUT_B <= Ram_Data_B;
        DOUT_C <= Ram_Data_C;
        DOUT_D <= Ram_Data_D;


end RTL;