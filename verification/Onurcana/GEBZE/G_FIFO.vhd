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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.P_SAGE_LIB.all;
 
entity G_FIFO is
  generic (
    FIFO_WIDTH 				: integer range 1 to 256	:= 32;
    FIFO_DEPTH 				: integer range 1 to 65536	:= 1024;
	FWFT					: boolean 					:= FALSE;
	Reset_Port 				: boolean 					:= FALSE;
	Reset_Latency 			: integer range 0 to 32		:= 0;
    Enable_Port 			: boolean 					:= FALSE;
    Data_Count_Port 		: boolean 					:= FALSE;
	Almost_Empty_Port 		: boolean 					:= FALSE;
	Almost_Empty_Treshold 	: integer range 1 to 65536 	:= 24;
	Almost_Full_Port 		: boolean 					:= FALSE;
	Almost_Full_Treshold 	: integer range 1 to 65536 	:= 1000
    );
  port (
  	CLK 		: in std_logic;
    RST 		: in std_logic;
	EN 			: in std_logic;
    -- FIFO Write Interface
    EN_WR   	: in  std_logic;
    D_IN 		: in  std_logic_vector(FIFO_WIDTH-1 downto 0);
    FULL    	: out std_logic;
    -- FIFO Read Interface
    EN_RD   	: in  std_logic;
    DOUT 		: out std_logic_vector(FIFO_WIDTH-1 downto 0);
    EMPTY   	: out std_logic;
	DATA_COUNT  : out std_logic_vector(clogb2(FIFO_DEPTH)-1 downto 0);
	A_E			: out std_logic;
	A_F 		: out std_logic
    );
end G_FIFO;
 
architecture RTL of G_FIFO is
 
  type t_ram is array (0 to FIFO_DEPTH -1) of std_logic_vector(FIFO_WIDTH-1 downto 0);
  signal r_FIFO_DATA 	: t_ram := (others => (others => '0'));
  signal r_WR_INDEX   	: integer range 0 to FIFO_DEPTH-1 := 0;
  signal r_RD_INDEX   	: integer range 0 to FIFO_DEPTH-1 := 0;

  signal r_FIFO_COUNT 	: integer range 0 to FIFO_DEPTH   := 0;
 
  signal w_FULL  		: std_logic;
  signal w_EMPTY 		: std_logic;
  
  signal Reset			: STD_LOGIC := '0';
  signal Enable_inside	: STD_LOGIC := '1';
  
  signal DOUT_REG		: std_logic_vector(FIFO_WIDTH-1 downto 0);
   
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
 	
		--FIFO control process
pr_CONTROL : process (CLK) is
begin											
	if rising_edge(CLK) then
		if Reset = '1' then
			r_FIFO_COUNT <= 0;
			r_WR_INDEX   <= 0;
			r_RD_INDEX   <= 0;
		elsif(Enable_inside = '1') then

		-- Keeps track of the total number of words in the FIFO
			if ((EN_WR = '1') and (EN_RD = '0')) then
				r_FIFO_COUNT <= r_FIFO_COUNT + 1;
			elsif ((EN_WR = '0') and (EN_RD = '1')) then
				r_FIFO_COUNT <= r_FIFO_COUNT - 1;
			end if;

		-- Keeps track of the write index (and controls roll-over)
			if ((EN_WR = '1') and (w_FULL = '0')) then
				if (r_WR_INDEX = (FIFO_DEPTH-1)) then
					r_WR_INDEX <= 0;
				else
					r_WR_INDEX <= r_WR_INDEX + 1;
				end if;
			end if;

		-- Keeps track of the read index (and controls roll-over)        
			if ((EN_RD = '1') and (w_EMPTY = '0')) then
				if (r_RD_INDEX = (FIFO_DEPTH-1)) then
					r_RD_INDEX <= 0;
				else
					r_RD_INDEX <= r_RD_INDEX + 1;
				end if;
			end if;

		-- Registers the input data when there is a write
			if EN_WR = '1' then
				r_FIFO_DATA(r_WR_INDEX) <= D_IN;
			end if;
		end if;                    
	end if;                        
end process pr_CONTROL;

if_STNDRT: if(FWFT = FALSE) generate   
	pr_read : process (CLK) is
	begin											
	if rising_edge(CLK) then
		if ((EN_RD = '1') and (w_EMPTY = '0')) then
			DOUT_REG <= r_FIFO_DATA(r_RD_INDEX);
		end if;
	end if;
	end process pr_read;
	DOUT <= DOUT_REG;
end generate;

if_FWFT: if(FWFT = TRUE) generate   
DOUT <= r_FIFO_DATA(r_RD_INDEX);
end generate;

w_FULL  <= '1' when r_FIFO_COUNT = FIFO_DEPTH else '0';
w_EMPTY <= '1' when r_FIFO_COUNT = 0       	  else '0';

FULL  <= w_FULL;
EMPTY <= w_EMPTY;
  

if_DC: if(Data_Count_Port = TRUE) generate     
	DATA_COUNT <= std_logic_vector(To_unsigned(r_FIFO_COUNT, DATA_COUNT'LENGTH));
end generate;
 
if_AF: if(Almost_Full_Port = TRUE) generate     
	A_F <= '1' when r_FIFO_COUNT >= Almost_Full_Treshold else '0';
end generate;

if_AE: if(Almost_Empty_Port = TRUE) generate     
	A_E <= '1' when r_FIFO_COUNT <= Almost_Empty_Treshold else '0';
end generate;  

end RTL;
