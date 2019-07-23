----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.05.2019 19:20:58
-- Design Name: 
-- Module Name: FPMULT - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FPMULT is
    Generic(Round			: boolean					:= TRUE;	--0: Truncate, 1: Round(unbiased: +/- inf)
			Overflow		: boolean					:= FALSE;	--0: Wrap, 1: Saturate
			Latency			: integer range 0 to 256	:= 3;
            Enable_Port 	: boolean					:= FALSE);
    Port   (CLK 		: in STD_LOGIC;
            EN          : in STD_LOGIC;
			A_SIG 		: in STD_LOGIC_VECTOR (31 downto 0);
			B_SIG 		: in STD_LOGIC_VECTOR (31 downto 0);
			MULT 		: out STD_LOGIC_VECTOR (31 downto 0));
end FPMULT;

architecture Behavioral of FPMULT is
type t_pipe is array(0 to Latency -1) of std_logic_vector(31 downto 0);
signal signA    :STD_LOGIC;
signal signB    :STD_LOGIC;
signal signZ    :STD_LOGIC;
signal expA	    :STD_LOGIC_VECTOR (7 downto 0);
signal expB	    :STD_LOGIC_VECTOR (7 downto 0);
signal expZ	    :STD_LOGIC_VECTOR (7 downto 0);
signal mantA    :STD_LOGIC_VECTOR (22 downto 0);
signal mantB    :STD_LOGIC_VECTOR (22 downto 0);
signal mantZ    :STD_LOGIC_VECTOR (22 downto 0);

signal multAB	:STD_LOGIC_VECTOR (47 downto 0);
signal biasedexp:STD_LOGIC_VECTOR (8 downto 0);
signal preexpZ  :STD_LOGIC_VECTOR (8 downto 0);

signal Enable_inside: STD_LOGIC := '1';
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pre_MULT		: STD_LOGIC_VECTOR (31 downto 0);


begin
	signA <= A_SIG(31);
	signB <= B_SIG(31);
	expA <=	A_SIG(7 downto 0);
	expB <=	B_SIG(7 downto 0);
	mantA <=A_SIG(22 downto 0);
	mantB <=B_SIG(22 downto 0);

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;


	signZ 	<= SignA xor signB;
	multAB 	<= std_logic_vector(unsigned('1' & mantA) * unsigned('1' & mantB));

	if_NR: if(Round = FALSE) generate     
		mantz   <= multAB(46 downto 24) when multAB(47) = '1' else multAB(45 downto 23);
	end generate if_NR;
	if_R: if(Round = TRUE) generate      
		mantz   <= std_logic_vector(unsigned(multAB(46 downto 24)) + unsigned(multAB(23 downto 23)))  when  multAB(47) = '1' 
			  else std_logic_vector(unsigned(multAB(45 downto 23)) + unsigned(multAB(22 downto 22)));
	end generate if_R;

	biasedexp 	<= std_logic_vector(unsigned('0' & expA) + unsigned('0' & expB));
	preexpZ    <= std_logic_vector(unsigned(biasedexp) - 127) when multAB(47) = '0' else std_logic_vector(unsigned(biasedexp) - 126);

	if_NO: if(Overflow = FALSE) generate     
		expZ    <= preexpZ(7 downto 0);
	end generate if_NO;
	if_O: if(Overflow = TRUE) generate      
		expZ    <= preexpZ(7 downto 0) when preexpZ(8) = '0' else (others=>'1');
	end generate if_O;
	
	pre_MULT    <= SignZ & expZ & mantZ;

	No_Latency: if(Latency = 0) generate
        MULT <= pre_MULT;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_MULT;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           MULT <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
            for i in 0 to Latency-2 loop
                pipe_reg(i+1) <= pipe_reg(i);
            end loop;
          end if;
        end process pr_pipe;
        MULT <= pipe_reg(Latency-1);
    end generate Lat_out;

end Behavioral;
