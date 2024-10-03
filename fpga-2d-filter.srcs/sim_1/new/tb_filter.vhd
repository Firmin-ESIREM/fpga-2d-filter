----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2024 15:06:39
-- Design Name: 
-- Module Name: tb_filter - Behavioral
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
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_filter is
--  Port ( );
end tb_filter;

architecture Behavioral of tb_filter is

component filter
  Port ( data_entry: IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel should be provided individually, line after line, on each clock rise, starting one clock rise after enable.
         data_output: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel of the provided image will be output individually, with a shift of { (width * 2) + 9 } clock cycles from the entry.
         valid_output: OUT STD_LOGIC;  -- This is set to 1 when the filter is currently outputing some valid pixels to the data_output bus.
         image_width: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         image_height: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         enable: IN STD_LOGIC;  -- This should be set to '1' when the image's width and height are provided, and should not be set back to '0' before you have retreived the whole output image. It should be set back to '0' before proceeding with another image.
         clock: IN STD_LOGIC;
         reset: IN STD_LOGIC
       );
end component;

signal data_entry_s: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal data_output_s: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal image_width_s: STD_LOGIC_VECTOR(9 DOWNTO 0);
signal image_height_s: STD_LOGIC_VECTOR(9 DOWNTO 0);
signal valid_output_s: STD_LOGIC;
signal enable_s: STD_LOGIC;
signal clock_s: STD_LOGIC;
signal reset_s: STD_LOGIC;


constant clock_period: time := 10 ns;
signal clock_init: STD_LOGIC;

begin

uut: filter 
      port map (  data_entry   => data_entry_s,
                  data_output  => data_output_s,
                  image_width  => image_width_s,
                  image_height => image_height_s,
                  valid_output => valid_output_s,
                  enable       => enable_s,
                  clock        => clock_s,
                  reset        => reset_s );
    
    stimulus: process
      FILE vectors: text;
      variable Iline: line;
      variable I1_var: std_logic_vector (7 downto 0);
      
      file results : text;
      variable OLine : line;
      variable O1_var :std_logic_vector (7 downto 0);
      begin
    file_open (vectors,"Lena128x128g_8bits.dat", read_mode);
    file_open (results,"Lena128x128g_8bits_r_filter.dat", write_mode);
    clock_init <= '0';
    reset_s <= '1';
    enable_s <= '0';
    data_entry_s <= std_logic_vector(to_unsigned(0, 8));
    image_width_s <= std_logic_vector(to_unsigned(0, 10));
    image_height_s <= std_logic_vector(to_unsigned(0, 10));
    
    wait for 3*clock_period;
    
    reset_s <= '0';

    wait for 10*clock_period;
    
    clock_init <= '1';
    
    wait for 10*clock_period;
    enable_s <= '1';
    image_width_s <= std_logic_vector(to_unsigned(128, 10));
    image_height_s <= std_logic_vector(to_unsigned(128, 10));
    
    wait for clock_period;   
    
    while not endfile(vectors) loop
      readline (vectors,Iline);
      read (Iline,I1_var);
                
      data_entry_s <= I1_var;
      if valid_output_s = '1' then
        write (Oline, data_output_s, right, 2);
        writeline (results, Oline);
      end if;
	  wait for clock_period;
    end loop;
    
    file_close(vectors);
    
    while valid_output_s = '1' loop
        write (Oline, data_output_s, right, 2);
        writeline (results, Oline);
        wait for clock_period;
    end loop;
    
    
    
    file_close(results);
     
    wait;
  end process;







clocking: process
  begin
     clock_s <= '0'; 
     wait for clock_period/2;
     clock_s <= clock_init;
     wait for clock_period/2;
  end process;


end Behavioral;
