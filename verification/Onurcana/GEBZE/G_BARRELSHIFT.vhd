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
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;

entity G_BARRELSHIFT is
    Generic( Input_Width 	: integer range 1 to 256	:= 8;
			 Direction		: integer range 0 to 2		:= 2; --0: Shift left, 1: right, 2: left and right, 3: left circular, 4: right circular, 5: left and right circular
             Enable_Port 	: boolean					:= FALSE;
			 Latency		: integer range 0 to 256	:= 0);
    Port ( CLK			    : in STD_LOGIC;
           EN				: in STD_LOGIC;
		   SHIFTPOS			: in STD_LOGIC_VECTOR (clogb2(Input_Width)-1 downto 0);
		   SHIFTDIR			: in STD_LOGIC;
		   A_SIG 			: in STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
           Z_SIG 			: out STD_LOGIC_VECTOR (Input_Width - 1 downto 0));
end G_BARRELSHIFT;

architecture RTL of G_BARRELSHIFT is

type t_pipe is array(0 to Latency -1) of std_logic_vector(Input_Width-1 downto 0);
type t_stage is array(0 to clogb2(Input_Width)) of std_logic_vector(Input_Width-1 downto 0);
signal stages	    : t_stage;
signal stages_aux	: t_stage;
signal zeros		: STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
signal Enable_inside: STD_LOGIC := '1';

signal pre_Z_SIG	: STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	
	zeros <= (others => '0');
	

	
	Left_S: if(Direction = 0) generate
		stages(0) <= A_SIG;
		Stage_loop:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages(variable_i - 1)(Input_Width - 1 - 2**(variable_i - 1) downto 0) & zeros(2**(variable_i - 1) - 1 downto 0);
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width));
	end generate Left_S;
	
	Right_S: if(Direction = 1) generate
		stages(0) <= A_SIG;
		Stage_loop:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			zeros(2**(variable_i - 1) - 1 downto 0) & stages(variable_i - 1)(Input_Width - 1 downto 2**(variable_i - 1)) ;
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width));
	end generate Right_S;
	
	LR_S: if(Direction = 2) generate
		stages(0) <= A_SIG;
		stages_aux(0) <= A_SIG;		
		Stage_loop0:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages(variable_i - 1)(Input_Width - 1 - 2**(variable_i - 1) downto 0) & zeros(2**(variable_i - 1) - 1 downto 0);
		end generate;
		Stage_loop1:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages_aux(variable_i) <= stages_aux(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			zeros(2**(variable_i - 1) - 1 downto 0) & stages_aux(variable_i - 1)(Input_Width - 1 downto 2**(variable_i - 1)) ;
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width)) when SHIFTDIR = '0' else stages_aux(clogb2(Input_Width));
	end generate LR_S;
	
	Left_SC: if(Direction = 0) generate
		stages(0) <= A_SIG;
		Stage_loop:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages(variable_i - 1)(Input_Width - 1 - 2**(variable_i - 1) downto 0) & stages(variable_i - 1)(Input_Width - 1 downto Input_Width - 2**(variable_i - 1));
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width));
	end generate Left_SC;
	
	Right_SC: if(Direction = 1) generate
		stages(0) <= A_SIG;
		Stage_loop:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages(variable_i - 1)(2**(variable_i - 1) - 1 downto 0) & stages(variable_i - 1)(Input_Width - 1 downto 2**(variable_i - 1)) ;
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width));
	end generate Right_SC;
	
	LR_SC: if(Direction = 2) generate
		stages(0) <= A_SIG;
		stages_aux(0) <= A_SIG;		
		Stage_loop0:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages(variable_i) <= stages(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages(variable_i - 1)(Input_Width - 1 - 2**(variable_i - 1) downto 0) & stages(variable_i - 1)(Input_Width - 1 downto Input_Width - 2**(variable_i - 1));
		end generate;
		Stage_loop1:for variable_i in 1 to clogb2(Input_Width) generate
		begin
            stages_aux(variable_i) <= stages_aux(variable_i - 1) when SHIFTPOS(variable_i - 1) = '0'     --No shift
			else
			stages_aux(variable_i - 1)(2**(variable_i - 1) - 1 downto 0) & stages_aux(variable_i - 1)(Input_Width - 1 downto 2**(variable_i - 1)) ;
		end generate;
		
		pre_Z_SIG <= stages(clogb2(Input_Width)) when SHIFTDIR = '0' else stages_aux(clogb2(Input_Width));
	end generate LR_SC;
	
	
	
	No_Latency: if(Latency = 0) generate
        Z_SIG <= pre_Z_SIG;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_Z_SIG;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           Z_SIG <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
          end if;
        end process pr_pipe;
        Z_SIG <= pipe_reg(Latency-1);
    end generate Lat_out;
end RTL;
