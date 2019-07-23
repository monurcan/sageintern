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

entity G_ADDSUB is
    Generic(
            Operation 		: integer range 0 to 3		:= 3;
            Latency		    : integer range 0 to 256	:= 0;
			Signed_Unsigned : boolean					:= FALSE;
            Width 			: integer range 1 to 256	:= 8;
            Reset_Port 		: boolean					:= FALSE;
			Carry_In_Port	: boolean					:= FALSE;
			Carry_Out_Port	: boolean					:= FALSE;
            Enable_Port 	: boolean					:= FALSE);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
			B_SIG 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
			C_IN			: in STD_LOGIC;
			SUB				: in STD_LOGIC;
			C_OUT			: out STD_LOGIC;
            SUM		 		: out STD_LOGIC_VECTOR (Width - 1 downto 0));
end G_ADDSUB;

architecture RTL of G_ADDSUB is
type t_pipe is array(0 to Latency -1) of std_logic_vector(Width-1 downto 0);
signal sum_reg				: STD_LOGIC_VECTOR (Width downto 0)		:= (others => '0');
signal A_in					: STD_LOGIC_VECTOR (Width downto 0)     := (others => '0');
signal B_in					: STD_LOGIC_VECTOR (Width downto 0)     := (others => '0');
signal Carry_In				: STD_LOGIC_VECTOR (0 downto 0)			:= "0";
signal Reset				: STD_LOGIC 							:= '0';
signal Enable_inside		: STD_LOGIC 							:= '1';
signal pipe_reg 			: t_pipe;  -- Pipelines for latency
signal pipe_out				: STD_LOGIC_VECTOR (Width - 1 downto 0);

  -- Optimal solution, using just one adder...

signal L_SIG, R_SIG			: Signed(Width downto 0);
signal Sum_reg_pre			: Signed(Width + 1 downto 0);
signal Cin					: Std_logic;

signal A8_SIG				: Signed(Width - 1 downto 0);
signal A9_SIG, B9_SIG		: Signed(Width downto 0);

signal UL_SIG, UR_SIG		: Unsigned(Width downto 0);
signal USum_reg_pre			: Unsigned(Width + 1 downto 0);
signal UCin					: Std_logic;

signal UA8_SIG				: Unsigned(Width - 1 downto 0);
signal UA9_SIG,UB9_SIG		: Unsigned(Width downto 0);
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
	
	if_NCI: if(Carry_In_Port = FALSE) generate     
        Carry_In <= "0";
	end generate if_NCI;
	if_CI: if(Carry_In_Port = TRUE) generate        
        Carry_In(0) <= C_IN;
    end generate if_CI;
	
	A_in(Width - 1 downto 0) <= A_SIG;
	B_in(Width - 1 downto 0) <= B_SIG;
    
    
    if_U:if(Signed_Unsigned = FALSE) generate
		if_0: if(Operation = 0) generate       -- Add
			sum_reg <= std_logic_vector(unsigned(A_in) + unsigned(B_in) + unsigned(Carry_In));
		end generate if_0;
		
		if_1: if(Operation = 1) generate       --Substract
			sum_reg <= std_logic_vector(unsigned(A_in) - unsigned(B_in) - unsigned(Carry_In));
		end generate if_1;

		if_2: if(Operation = 2) generate       --ADD Substract
			sum_reg <= std_logic_vector(unsigned(A_in) + unsigned(B_in) + unsigned(Carry_In)) when SUB = '0' 
			else std_logic_vector(unsigned(A_in) - unsigned(B_in) - unsigned(Carry_In));
		end generate if_2;
		
		if_3: if(Operation = 3) generate      --Add substract optimum
            UA8_SIG <= unsigned(A_SIG);
            UA9_SIG <= Resize(unsigned(A_SIG), Width + 1);
            UB9_SIG <= Resize(unsigned(B_SIG), Width + 1);
            pr_addsub:process (UA8_SIG, UA9_SIG, UB9_SIG, SUB)
            begin
                case_s:case SUB is
                when '0' =>
                    UL_SIG   <= UA9_SIG;
                    UR_SIG   <= UB9_SIG;
                    Cin <= '0';
                when '1' =>
                    UL_SIG   <= UA9_SIG;
                    UR_SIG   <= not UB9_SIG;
                    Cin <= '1';
				when others =>
                    UL_SIG   <= UA9_SIG;
                    UR_SIG   <= UB9_SIG;
                    Cin <= '0';					
                end case case_s;
            end process pr_addsub;
            Usum_reg_pre <= (UL_SIG & '1') + (UR_SIG & Carry_In(0));
            sum_reg(Width downto 0) <= std_logic_vector(Usum_reg_pre(Width + 1 downto 1));
        end generate if_3;
	end generate if_U;
	
	if_S:if(Signed_Unsigned = TRUE) generate
		if_0: if(Operation = 0) generate       -- Add
			sum_reg <= std_logic_vector(signed(A_in) + signed(B_in) + signed(Carry_In));
		end generate if_0;
		
		if_1: if(Operation = 1) generate       --Substract
			sum_reg <= std_logic_vector(signed(A_in) - signed(B_in) - signed(Carry_In));
		end generate if_1;

		if_2: if(Operation = 2) generate       --Substract
			sum_reg <= std_logic_vector(signed(A_in) + signed(B_in) + signed(Carry_In)) when SUB = '0' 
			else std_logic_vector(signed(A_in) - signed(B_in) - signed(Carry_In));
		end generate if_2;
        
        if_3: if(Operation = 3) generate
            A8_SIG <= signed(A_SIG);
            A9_SIG <= Resize(signed(A_SIG), Width + 1);
            B9_SIG <= Resize(signed(B_SIG), Width + 1);
            pr_addsub:process (A8_SIG, A9_SIG, B9_SIG, SUB)
            begin
                case_s:case SUB is
                when '0' =>
                    L_SIG   <= A9_SIG;
                    R_SIG   <= B9_SIG;
                    Cin <= '0';
                when '1' =>
                    L_SIG   <= A9_SIG;
                    R_SIG   <= not B9_SIG;
                    Cin <= '1';
				when others =>
                    L_SIG   <= A9_SIG;
                    R_SIG   <= B9_SIG;
                    Cin <= '0';	
                end case case_s;
            end process pr_addsub;
            sum_reg_pre <= (L_SIG & '1') + (R_SIG & Carry_In(0));
            sum_reg(Width downto 0) <= std_logic_vector(sum_reg_pre(Width + 1 downto 1));
        end generate if_3;
    end generate if_S;

	
	No_Latency: if(Latency = 0) generate
        SUM <= sum_reg(Width - 1 downto 0);
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
				if(Reset = '1') then
					pipe_reg(0) <= (others => '0');
				else
					if(Enable_inside = '1' ) then
						pipe_reg(0) <= sum_reg(Width - 1 downto 0);
					end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           SUM <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency) <= pipe_reg(0 to Latency-1);
          end if;
        end process pr_pipe;
        SUM <= pipe_reg(Latency-1);
    end generate Lat_out;

	if_CO: if(Carry_Out_Port = TRUE) generate        
        C_OUT <= sum_reg(Width);
    end generate if_CO;
end RTL;
