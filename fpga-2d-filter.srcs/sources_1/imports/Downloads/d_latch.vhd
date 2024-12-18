----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.09.2024 14:36:26
-- Design Name: 
-- Module Name: d_latch - d_latch_arch
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity d_latch is
    generic (
        bus_width : integer := 8
    );
    Port ( D : in STD_LOGIC_VECTOR (bus_width - 1 downto 0);
           Q : out STD_LOGIC_VECTOR (bus_width - 1 downto 0);
           CLK : in STD_LOGIC;
           EN : in STD_LOGIC;
           RESET : in STD_LOGIC
     );
end d_latch;

architecture d_latch_arch of d_latch is

signal temp: STD_LOGIC_VECTOR (bus_width - 1 downto 0);

begin

p1: process(CLK,RESET)
begin
    if (RESET ='1') then temp <= (others => '0');
    elsif (CLK'event and CLK='1') then
        if (EN ='1') then
            temp <= D;                       
        end if;
    end if;
end process;

Q <= temp;

end d_latch_arch;
