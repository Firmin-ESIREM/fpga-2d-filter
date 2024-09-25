----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2024 16:12:45
-- Design Name: 
-- Module Name: ut_fifo - Behavioral
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
use ieee.numeric_std.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ut_fifo is
--  Port ( );
end ut_fifo;

architecture Behavioral of ut_fifo is

COMPONENT fifo
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    prog_full_thresh : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT;

signal clk_s: STD_LOGIC;
signal rst_s: STD_LOGIC;
signal din_s: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal wr_en_s: STD_LOGIC;
signal rd_en_s: STD_LOGIC;
signal prog_full_thresh_s: STD_LOGIC_VECTOR(9 DOWNTO 0);
signal dout_s: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal full_s: STD_LOGIC;
signal empty_s: STD_LOGIC;
signal prog_full_s: STD_LOGIC;


constant fixed_period: time := 10 ns;
signal clock_init: STD_LOGIC;

begin

uut: fifo
    PORT MAP ( clk              => clk_s,
               rst              => rst_s,
               din              => din_s,
               wr_en            => wr_en_s,
               rd_en            => rd_en_s,
               prog_full_thresh => prog_full_thresh_s,
               dout             => dout_s,
               full             => full_s,
               empty            => empty_s,
               prog_full        => prog_full_s
             );

stimulus: process
begin
    clock_init <= '0';
    rst_s <= '1';
    wr_en_s <= '0';
    rd_en_s <= '0';
    prog_full_thresh_s <= std_logic_vector(to_unsigned(256, prog_full_thresh_s'length));
    
    wait for fixed_period*10;
    clock_init <= '1';
    rst_s <= '0';
    
    wait for fixed_period*10;
    
    wr_en_s <= '1';
     
    din_s <= x"20";
    
    wait for fixed_period;
    
    rd_en_s <= '1';
    din_s <= x"0F";
    
    wait for fixed_period;
    
    din_s <= x"A1";
    
    
    wait;
end process;


clocking: process
begin
    clk_s <= '0'; 
    wait for fixed_period/2;
    clk_s <= clock_init;
    wait for fixed_period/2;
end process;






end Behavioral;
