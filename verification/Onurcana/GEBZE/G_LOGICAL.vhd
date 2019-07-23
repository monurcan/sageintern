----------------------------------------------------------------------------------
-- Company: TUBITAK SAGE
-- Engineer: Adem GUNESEN
-- 
-- Create Date: 01.04.2019 16:07:19
-- Design Name: Relational
-- Module Name: G_LOGICAL - RTL
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
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;


entity G_LOGICAL is
    Generic(
            Logical_Function: string 				:= "AND"; --AND, NAND, OR, NOR, XOR, XNOR
            Input_Ports		: integer range 2 to 256:= 8;
			Input_Width		: integer range 1 to 256:= 4;
            Enable_Port 	: boolean 				:= TRUE;
			Latency			: integer range 0 to 256:= 0);
    Port (  CLK 			: in STD_LOGIC;
			EN   			: in STD_LOGIC;
			SIGNALS 		: in STD_LOGIC_VECTOR (Input_Width*Input_Ports - 1 downto 0);
            Z_SIG       	: out std_logic_vector(Input_Width-1 downto 0));
end G_LOGICAL;

architecture RTL of G_LOGICAL is
	type t_pipe is array(0 to Latency -1) of std_logic_vector(0 downto 0);
    signal Z_SIG_pre       	: std_logic_vector(Input_Width-1 downto 0);
	signal Enable_inside	: STD_LOGIC := '1';
	signal pipe_reg 		: t_pipe;
	signal pipe_out			: STD_LOGIC_VECTOR (0 downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	
	if_0: if Logical_Function = "AND" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '1';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result and SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= v_result;
        end loop;
        end process pr_calc;
	end generate if_0;

	if_1: if Logical_Function = "NAND" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '1';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result and SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= not v_result;
        end loop;
        end process pr_calc;
	end generate if_1;
	
	if_2: if Logical_Function = "OR" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '0';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result or SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= v_result;
        end loop;
        end process pr_calc;
	end generate if_2;
	
	if_3: if Logical_Function = "NOR" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '0';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result or SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= not v_result;
        end loop;
        end process pr_calc;
	end generate if_3;
	
	if_4: if Logical_Function = "XOR" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '0';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result xor SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= v_result;
        end loop;
        end process pr_calc;
	end generate if_4;
	
	if_5: if Logical_Function = "XNOR" generate
        pr_calc:process(SIGNALS)
        variable v_i     : integer := 0;
        variable v_j     : integer := 0;
        variable v_result    : std_logic;
        begin
        for v_i in 0 to Input_Width - 1 loop
           v_result := '0';
           for v_j in 0 to Input_Ports - 1 loop
               v_result := v_result xor SIGNALS(Input_Width*v_j + v_i);
           end loop;
           Z_SIG_pre(v_i) <= not v_result;
        end loop;
        end process pr_calc;  
	end generate if_5;
	
	No_Latency: if(Latency = 0) generate
        Z_SIG <= Z_SIG_pre;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= Z_SIG_pre;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           Z_SIG <= pipe_reg(0);
    end generate Lat_1; 

    Lat_Out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
          end if;
        end process pr_pipe;
        Z_SIG <= pipe_reg(Latency-1);
    end generate Lat_out;

end RTL;
