-- Single Bit Metastability Resolution Circuit*/
library ieee;     
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
    
entity G_SBITMETA is
    generic 
    (
        C_DATA_WIDTH                : integer   := 1  -- Data Width
    );
    port 
    (
        CLK_IN                      : in std_logic;-- Input clock
        CLK_OUT                     : in std_logic;-- Output clock      
         
        DATA_IN                     : in std_logic_vector(C_DATA_WIDTH-1 downto 0);-- Data input
        DATA_OUT                    : out std_logic_vector(C_DATA_WIDTH-1 downto 0)-- Data output
   );
end G_SBITMETA;
   
architecture rtl of G_SBITMETA is

    signal data_src_reg				: std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');      
	signal data_meta_reg			: std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
	signal data_out_reg				: std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
begin

    pr_SRC_REG: process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN='1' then 
            data_src_reg <= DATA_IN;
        end if;
    end process pr_SRC_REG;
    
    pr_OUT_REG: process(CLK_OUT)
    begin
        if CLK_OUT'event and CLK_OUT='1' then 
            data_meta_reg <= data_src_reg;
            data_out_reg <= data_meta_reg;
        end if;
    end process pr_OUT_REG;
    
    DATA_OUT <= data_out_reg;

end architecture rtl;