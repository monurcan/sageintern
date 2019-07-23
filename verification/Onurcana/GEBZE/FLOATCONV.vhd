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

entity G_FLOATCONV is
    Generic(
            --Operation 		: integer range 0 to 3		:= 3;
            Latency		    : integer range 0 to 256	:= 0;
			--Signed_Unsigned : boolean					:= FALSE;
            --Width 			: integer range 1 to 256	:= 8;
            Reset_Port 		: boolean					:= FALSE;
			--Carry_In_Port	: boolean					:= FALSE;
			--Carry_Out_Port	: boolean					:= FALSE;
            Enable_Port 	: boolean					:= FALSE);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (31 downto 0);
			--C_IN			: in STD_LOGIC;
			--SUB				: in STD_LOGIC;
			--C_OUT			: out STD_LOGIC;
			SIGN            : out STD_LOGIC;
			EXP             : out STD_LOGIC_VECTOR (7 downto 0);
			MANT            : out STD_LOGIC_VECTOR (22 downto 0);
            FLOAT		 	: out STD_LOGIC_VECTOR (31 downto 0));
end G_FLOATCONV;

architecture RTL of G_FLOATCONV is
type t_pipe is array(0 to Latency -1) of std_logic_vector(31 downto 0);

signal Reset		: STD_LOGIC 							:= '0';
signal Enable_inside: STD_LOGIC 							:= '1';
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (31 downto 0);

signal comp_a		: STD_LOGIC_VECTOR (31 downto 0);
signal sign_a		: STD_LOGIC 							:= '0';
signal calculate_exp		: STD_LOGIC 							:= '0';
signal exp_a		: STD_LOGIC_VECTOR (7 downto 0);
signal mant_a		: STD_LOGIC_VECTOR (22 downto 0);


begin
    
    if_NE: if(Enable_Port = FALSE) generate     
        Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate
        Enable_inside <= EN;
    end generate if_E;
    
    if_NR: if(Reset_Port = FALSE) generate     
        Reset <= '0';
	end generate if_NR;
	if_R: if(Reset_Port = TRUE) generate        
        Reset <= RST;
    end generate if_R;
	
	comp_a <= std_logic_vector(signed(not A_SIG) + 1);
	sign_a <= A_SIG(31);
	with sign_a select	
	calculate_exp <='1' when '0',
	                '0' when '1',
	                '0' when others;
	
	pr_exp:process(calculate_exp, comp_a, A_SIG)
	begin
		if(calculate_exp = '1') then
			case(A_SIG(30 downto 0)) is
				when "1------------------------------" => exp_a <= std_logic_vector(to_unsigned(30, 8) +127); mant_a <= A_SIG(29 downto 7);
				when "01-----------------------------" => exp_a <= std_logic_vector(to_unsigned(29, 8) +127); mant_a <= A_SIG(28 downto 6);
				when "001----------------------------" => exp_a <= std_logic_vector(to_unsigned(28, 8) +127); mant_a <= A_SIG(27 downto 5);
				when "0001---------------------------" => exp_a <= std_logic_vector(to_unsigned(27, 8) +127); mant_a <= A_SIG(26 downto 4);
				when "00001--------------------------" => exp_a <= std_logic_vector(to_unsigned(26, 8) +127); mant_a <= A_SIG(25 downto 3);
				when "000001-------------------------" => exp_a <= std_logic_vector(to_unsigned(25, 8) +127); mant_a <= A_SIG(24 downto 2);
				when "0000001------------------------" => exp_a <= std_logic_vector(to_unsigned(24, 8) +127); mant_a <= A_SIG(23 downto 1);
				when "00000001-----------------------" => exp_a <= std_logic_vector(to_unsigned(23, 8) +127); mant_a <= A_SIG(22 downto 0);
				when "000000001----------------------" => exp_a <= std_logic_vector(to_unsigned(22, 8) +127); mant_a <= A_SIG(21 downto 0) & "0";
				when "0000000001---------------------" => exp_a <= std_logic_vector(to_unsigned(21, 8) +127); mant_a <= A_SIG(20 downto 0) & "00";
				when "00000000001--------------------" => exp_a <= std_logic_vector(to_unsigned(20, 8) +127); mant_a <= A_SIG(19 downto 0) & "000";
				when "000000000001-------------------" => exp_a <= std_logic_vector(to_unsigned(19, 8) +127); mant_a <= A_SIG(18 downto 0) & "0000";
				when "0000000000001------------------" => exp_a <= std_logic_vector(to_unsigned(18, 8) +127); mant_a <= A_SIG(17 downto 0) & "00000";
				when "00000000000001-----------------" => exp_a <= std_logic_vector(to_unsigned(17, 8) +127); mant_a <= A_SIG(16 downto 0) & "000000";
				when "000000000000001----------------" => exp_a <= std_logic_vector(to_unsigned(16, 8) +127); mant_a <= A_SIG(15 downto 0) & "0000000";
				when "0000000000000001---------------" => exp_a <= std_logic_vector(to_unsigned(15, 8) +127); mant_a <= A_SIG(14 downto 0) & "00000000";
				when "00000000000000001--------------" => exp_a <= std_logic_vector(to_unsigned(14, 8) +127); mant_a <= A_SIG(13 downto 0) & "000000000";
				when "000000000000000001-------------" => exp_a <= std_logic_vector(to_unsigned(13, 8) +127); mant_a <= A_SIG(12 downto 0) & "0000000000";
				when "0000000000000000001------------" => exp_a <= std_logic_vector(to_unsigned(12, 8) +127); mant_a <= A_SIG(11 downto 0) & "00000000000";
				when "00000000000000000001-----------" => exp_a <= std_logic_vector(to_unsigned(11, 8) +127); mant_a <= A_SIG(10 downto 0) & "000000000000";
				when "000000000000000000001----------" => exp_a <= std_logic_vector(to_unsigned(10, 8) +127); mant_a <= A_SIG(9 downto 0)  & "0000000000000";
				when "0000000000000000000001---------" => exp_a <= std_logic_vector(to_unsigned(9, 8)  +127); mant_a <= A_SIG(8 downto 0)  & "00000000000000";
				when "00000000000000000000001--------" => exp_a <= std_logic_vector(to_unsigned(8, 8)  +127); mant_a <= A_SIG(7 downto 0)  & "000000000000000";
				when "000000000000000000000001-------" => exp_a <= std_logic_vector(to_unsigned(7, 8)  +127); mant_a <= A_SIG(6 downto 0)  & "0000000000000000";
				when "0000000000000000000000001------" => exp_a <= std_logic_vector(to_unsigned(6, 8)  +127); mant_a <= A_SIG(5 downto 0)  & "00000000000000000";
				when "00000000000000000000000001-----" => exp_a <= std_logic_vector(to_unsigned(5, 8)  +127); mant_a <= A_SIG(4 downto 0)  & "000000000000000000";
				when "000000000000000000000000001----" => exp_a <= std_logic_vector(to_unsigned(4, 8)  +127); mant_a <= A_SIG(3 downto 0)  & "0000000000000000000";
				when "0000000000000000000000000001---" => exp_a <= std_logic_vector(to_unsigned(3, 8)  +127); mant_a <= A_SIG(2 downto 0)  & "00000000000000000000";
	            when "00000000000000000000000000001--" => exp_a <= std_logic_vector(to_unsigned(2, 8)  +127); mant_a <= A_SIG(1 downto 0)  & "000000000000000000000";
	            when "000000000000000000000000000001-" => exp_a <= std_logic_vector(to_unsigned(1, 8)  +127); mant_a <= A_SIG(0 downto 0)  & "0000000000000000000000";
	            when "0000000000000000000000000000001" => exp_a <= std_logic_vector(to_unsigned(0, 8)  +127); mant_a <= "00000000000000000000000";
				when others 						   => exp_a <= std_logic_vector(to_unsigned(0, 8)  +127); mant_a <= "00000000000000000000000";
			end case;
		else
			case(comp_a(30 downto 0)) is
				when "1------------------------------" => exp_a <= std_logic_vector(to_unsigned(157, 8) ); mant_a <= A_SIG(29 downto 7);
				when "01-----------------------------" => exp_a <= std_logic_vector(to_unsigned(156, 8) ); mant_a <= A_SIG(28 downto 6);
				when "001----------------------------" => exp_a <= std_logic_vector(to_unsigned(155, 8) ); mant_a <= A_SIG(27 downto 5);
				when "0001---------------------------" => exp_a <= std_logic_vector(to_unsigned(154, 8) ); mant_a <= A_SIG(26 downto 4);
				when "00001--------------------------" => exp_a <= std_logic_vector(to_unsigned(153, 8) ); mant_a <= A_SIG(25 downto 3);
				when "000001-------------------------" => exp_a <= std_logic_vector(to_unsigned(152, 8) ); mant_a <= A_SIG(24 downto 2);
				when "0000001------------------------" => exp_a <= std_logic_vector(to_unsigned(151, 8) ); mant_a <= A_SIG(23 downto 1);
				when "00000001-----------------------" => exp_a <= std_logic_vector(to_unsigned(150, 8) ); mant_a <= A_SIG(22 downto 0);
				when "000000001----------------------" => exp_a <= std_logic_vector(to_unsigned(149, 8) ); mant_a <= A_SIG(21 downto 0) & "0";
				when "0000000001---------------------" => exp_a <= std_logic_vector(to_unsigned(148, 8) ); mant_a <= A_SIG(20 downto 0) & "00";
				when "00000000001--------------------" => exp_a <= std_logic_vector(to_unsigned(147, 8) ); mant_a <= A_SIG(19 downto 0) & "000";
				when "000000000001-------------------" => exp_a <= std_logic_vector(to_unsigned(146, 8) ); mant_a <= A_SIG(18 downto 0) & "0000";
				when "0000000000001------------------" => exp_a <= std_logic_vector(to_unsigned(145, 8) ); mant_a <= A_SIG(17 downto 0) & "00000";
				when "00000000000001-----------------" => exp_a <= std_logic_vector(to_unsigned(144, 8) ); mant_a <= A_SIG(16 downto 0) & "000000";
				when "000000000000001----------------" => exp_a <= std_logic_vector(to_unsigned(143, 8) ); mant_a <= A_SIG(15 downto 0) & "0000000";
				when "0000000000000001---------------" => exp_a <= std_logic_vector(to_unsigned(142, 8) ); mant_a <= A_SIG(14 downto 0) & "00000000";
				when "00000000000000001--------------" => exp_a <= std_logic_vector(to_unsigned(141, 8) ); mant_a <= A_SIG(13 downto 0) & "000000000";
				when "000000000000000001-------------" => exp_a <= std_logic_vector(to_unsigned(140, 8) ); mant_a <= A_SIG(12 downto 0) & "0000000000";
				when "0000000000000000001------------" => exp_a <= std_logic_vector(to_unsigned(139, 8) ); mant_a <= A_SIG(11 downto 0) & "00000000000";
				when "00000000000000000001-----------" => exp_a <= std_logic_vector(to_unsigned(138, 8) ); mant_a <= A_SIG(10 downto 0) & "000000000000";
				when "000000000000000000001----------" => exp_a <= std_logic_vector(to_unsigned(137, 8) ); mant_a <= A_SIG(9 downto 0)  & "0000000000000";
				when "0000000000000000000001---------" => exp_a <= std_logic_vector(to_unsigned(136, 8)); mant_a <= A_SIG(8 downto 0)  & "00000000000000";
				when "00000000000000000000001--------" => exp_a <= std_logic_vector(to_unsigned(135, 8)); mant_a <= A_SIG(7 downto 0)  & "000000000000000";
				when "000000000000000000000001-------" => exp_a <= std_logic_vector(to_unsigned(134, 8)); mant_a <= A_SIG(6 downto 0)  & "0000000000000000";
				when "0000000000000000000000001------" => exp_a <= std_logic_vector(to_unsigned(133, 8)); mant_a <= A_SIG(5 downto 0)  & "00000000000000000";
				when "00000000000000000000000001-----" => exp_a <= std_logic_vector(to_unsigned(132, 8)); mant_a <= A_SIG(4 downto 0)  & "000000000000000000";
				when "000000000000000000000000001----" => exp_a <= "10000011"; mant_a <= A_SIG(3 downto 0)  & "0000000000000000000";
				when "0000000000000000000000000001---" => exp_a <= std_logic_vector(to_unsigned(130, 8)); mant_a <= A_SIG(2 downto 0)  & "00000000000000000000";
	            when "00000000000000000000000000001--" => exp_a <= std_logic_vector(to_unsigned(129, 8)); mant_a <= A_SIG(1 downto 0)  & "000000000000000000000";
	            when "000000000000000000000000000001-" => exp_a <= std_logic_vector(to_unsigned(128, 8)); mant_a <= A_SIG(0 downto 0)  & "0000000000000000000000";
	            when "0000000000000000000000000000001" => exp_a <= std_logic_vector(to_unsigned(127, 8)); mant_a <= "00000000000000000000000";
				when others 						   => exp_a <= std_logic_vector(to_unsigned(127, 8)); mant_a <= "00000000000000000000000";
			end case;
		end if;
	end process;
	
	FLOAT <= sign_a & exp_a & mant_a;
	SIGN <= sign_a;
	EXP <= exp_a;
	MANT <= mant_a;

	
--	No_Latency: if(Latency = 0) generate
--        SUM <= sum_reg(Width - 1 downto 0);
--    end generate No_Latency;
    
--    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
--        pr_pipe_in:process(CLK)									
--        begin									          
--            if(CLK'event and CLK = '1') then
--				if(Reset = '1') then
--					pipe_reg(0) <= (others => '0');
--				else
--					if(Enable_inside = '1' ) then
--						pipe_reg(0) <= sum_reg(Width - 1 downto 0);
--					end if;
--				end if;
--            end if;
--        end process pr_pipe_in;
--    end generate Lat;
    
--    Lat_1: if(Latency = 1) generate
--           SUM <= pipe_reg(0);
--    end generate Lat_1; 

--    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
--        pr_pipe:process(CLK)									
--        begin										
--          if(CLK'event and CLK = '1') then
--            for i in 0 to Latency-1 loop
--                pipe_reg(i+1) <= pipe_reg(i);
--            end loop;
--          end if;
--        end process pr_pipe;
--        SUM <= pipe_reg(Latency-1);
--    end generate Lat_out;

--	if_CO: if(Carry_Out_Port = TRUE) generate        
--        C_OUT <= sum_reg(Width);
--    end generate if_CO;
end RTL;
