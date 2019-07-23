----------------------------------------------------------------------------------
-- Company: TUBITAK SAGE
-- Engineer: Adem GUNESEN
-- 
-- Create Date: 01.04.2019 16:07:19
-- Design Name: Relational
-- Module Name: G_RELATIONAL - RTL
-- Project Name: Relational
-- Target Devices: Unconstrained
-- Tool Versions: Vivado 2016.3
-- Description: A generic relational logic implementation based on System Generator Relational block
--              for A=B, A!=B, A>B, A<B, A>=B, A<=B conditions.
--              Output Z_SIG = 1 if the specified condition holds.
-- Dependencies: None
-- 
-- Revision: 1
-- Revision 0.01 - File Created
-- Additional Comments: --
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;

entity G_TRUEDPRAM is
    Generic(
           RAM_WIDTH		: integer range 1 to 256  := 32;
           RAM_DEPTH        : integer range 1 to 65536:= 16;
           INIT_FILE        : string                  := "All zeros"; 
           Two_CLK          : boolean                 := TRUE;
           Write_Mode		: integer range 0 to 2    := 0;
		   Reset_Port_A     : boolean                 := TRUE;
           Enable_Port_A    : boolean                 := TRUE;
           Latency_A        : integer range 1 to 256  := 4;
           Reset_Port_B     : boolean                 := TRUE;
           Enable_Port_B    : boolean                 := TRUE;
           Latency_B        : integer range 1 to 256  := 4);
    Port ( CLK_A 			: in STD_LOGIC;
           CLK_B 			: in STD_LOGIC;
		   RST_A 			: in STD_LOGIC;
           RST_B 			: in STD_LOGIC;
		   EN_A 			: in STD_LOGIC;
           EN_B 			: in STD_LOGIC;
           ADDR_A 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           ADDR_B 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           DATA_A 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);   
		   DATA_B 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0); 		   
           WR_EN_A 			: in STD_LOGIC;
		   WR_EN_B 			: in STD_LOGIC;
		   DOUT_A 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);
           DOUT_B 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0));   
end G_TRUEDPRAM;

architecture RTL of G_TRUEDPRAM is

type t_ram is array (0 to RAM_DEPTH -1) of std_logic_vector(RAM_WIDTH-1 downto 0);
type t_pipe_A is array(0 to Latency_A -1) of std_logic_vector(RAM_WIDTH-1 downto 0);
type t_pipe_B is array(0 to Latency_B -1) of std_logic_vector(RAM_WIDTH-1 downto 0);

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
signal Reset_A          : STD_LOGIC := '0';
signal Reset_B          : STD_LOGIC := '0';
signal Enable_inside_A  : STD_LOGIC := '1';
signal Enable_inside_B  : STD_LOGIC := '1';
signal pipe_reg_A       : t_pipe_A;  -- Pipelines for Memory
signal pipe_reg_B       : t_pipe_B;  -- Pipelines for Memory

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


if_NR_A: if(Reset_Port_A = FALSE) generate     
    Reset_A <= '0';
end generate if_NR_A;
if_R_A: if(Reset_Port_A = TRUE) generate      
    Reset_A <= RST_A;
end generate if_R_A;

if_NR_B: if(Reset_Port_B = FALSE) generate     
    Reset_B <= '0';
end generate if_NR_B;
if_R_B: if(Reset_Port_B = TRUE) generate      
    Reset_B <= RST_B;
end generate if_R_B;

if_Mode_0:if(Write_Mode = 0) generate
    
    if_1_CLK_0: if(Two_CLK = FALSE) generate						--Read after write 1 clock
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
        end if;
        if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;
        end if;
    end process pr_clk_1;
    end generate;
    
    if_2_CLK_0: if(Two_CLK = TRUE) generate							--Read after write 2 clock
    pr_clk_2:process(CLK_A, CLK_B)								
    begin
	    if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                else
                    Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                end if;
            end if;
        end if;
        if(CLK_B'event and CLK_B = '1') then
            if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;
        end if;
    end process pr_clk_2;
    end generate;
end generate;

if_Mode_1:if(Write_Mode = 1) generate
    
    if_1_CLK_1: if(Two_CLK = FALSE) generate						--Read before write 1 clock
    pr_clk_1_1:process(CLK_A)										
    begin
	    if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                end if;
            end if;
        end if;
        if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_B = '1') then
                Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                end if;
            end if;
        end if;
    end process pr_clk_1_1;
    end generate;
    
    if_2_CLK_1: if(Two_CLK = TRUE) generate							--Read before write 2 clock
    pr_clk_2_1:process(CLK_A, CLK_B)								
    begin
	    if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_A = '1') then
                Ram_Data_A <= DP_RAM(to_integer(unsigned(ADDR_A)));
                if(WR_EN_A = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
                end if;
            end if;
        end if;
        if(CLK_B'event and CLK_B = '1') then
            if(Enable_inside_B = '1') then
                Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                end if;
            end if;
        end if;
    end process pr_clk_2_1;
    end generate;
end generate;

if_Mode_2:if(Write_Mode = 2) generate
    
    if_1_CLK_2: if(Two_CLK = FALSE) generate						--No read on write 1 clock
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
        end if;
        if(CLK_A'event and CLK_A = '1') then
            if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                    Ram_Data_B <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;
        end if;
    end process pr_clk_1_2;
    end generate;
    
    if_2_CLK_2: if(Two_CLK = TRUE) generate							--No read on write 2 clock
    pr_clk_2_2:process(CLK_A, CLK_B)								
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
        end if;
        if(CLK_B'event and CLK_B = '1') then
            if(Enable_inside_B = '1') then
                if(WR_EN_B = '1') then
                    DP_RAM(to_integer(unsigned(ADDR_B))) <= DATA_B;
                    Ram_Data_B <= DATA_B;
                else
                    Ram_Data_B <= DP_RAM(to_integer(unsigned(ADDR_B)));
                end if;
            end if;
        end if;
    end process pr_clk_2_2;
    end generate;    
end generate;

	No_Latency_A: if(Latency_A = 1) generate
        DOUT_A <= Ram_Data_A;
    end generate No_Latency_A;
    
    Lat_A: if(Latency_A > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK_A)									
        begin									          
            if(CLK_A'event and CLK_A = '1') then
				if(Reset_A = '1') then
					pipe_reg_A(0) <= (others => '0');
				else
	                if(Enable_Inside_A = '1') then
	                    pipe_reg_A(0) <= Ram_Data_A;
	                end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat_A;
    
    Lat_1_A: if(Latency_A = 2) generate
    	DOUT_A <= pipe_reg_A(0);
    end generate Lat_1_A; 

    Lat_out_A: if(Latency_A > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK_A)									
        begin										
          if(CLK_A'event and CLK_A = '1') then
		  	if(Reset_A = '1') then
				for i in 0 to Latency_A-2 loop
					pipe_reg_A(i+1) <= (others => '0');
				end loop;
			else
	            if(Enable_Inside_A = '1') then
	                for i in 0 to Latency_A-2 loop
	                    pipe_reg_A(i+1) <= pipe_reg_A(i);
	                end loop;
	            end if;
			end if;
          end if;
        end process pr_pipe;
        DOUT_A <= pipe_reg_A(Latency_A-2);
    end generate Lat_out_A;

	No_Latency_B: if(Latency_B = 1) generate
        DOUT_B <= Ram_Data_B;
    end generate No_Latency_B;
    
    Lat_B: if(Latency_B > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK_B)									
        begin									          
            if(CLK_B'event and CLK_B = '1') then
				if(Reset_B = '1') then
					pipe_reg_B(0) <= (others => '0');
				else
	                if(Enable_Inside_B = '1') then
	                    pipe_reg_B(0) <= Ram_Data_B;
	                end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat_B;
    
    Lat_1_B: if(Latency_B = 2) generate
           DOUT_B <= pipe_reg_B(0);
    end generate Lat_1_B; 

    Lat_out_B: if(Latency_B > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK_B)									
        begin										
          if(CLK_B'event and CLK_B = '1') then
		  	if(Reset_B = '1') then
					pipe_reg_B(1 to Latency_B-1) <= (others =>(others => '0'));
			else
	            if(Enable_Inside_B = '1') then
	                pipe_reg_B(1 to Latency_B-1) <= pipe_reg_B(0 to Latency_B-2);
	            end if;
			end if;
          end if;
        end process pr_pipe;
        DOUT_B <= pipe_reg_B(Latency_B-2);
    end generate Lat_out_B;

end RTL;