----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2024 14:44:33
-- Design Name: 
-- Module Name: filter - Behavioral
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

entity filter is
  Port ( data_entry: IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel should be provided individually, line after line, on each clock rise.
         data_output: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel of the provided image will be output individually, with a shift of { (width * 2) + 9 } clock cycles from the entry.
         valid_output: OUT STD_LOGIC;  -- This is set to 1 when the filter is currently outputing some valid pixels to the data_output bus.
         image_width: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         image_height: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         enable: IN STD_LOGIC;  -- This should be set to '1' when the image's width and height are provided, along with the first pixel, and should not be set back to '0' before you have provided the whole image. It should be set back to '0' before proceeding with another image.
         clock: IN STD_LOGIC;
         reset: IN STD_LOGIC
       );
end filter;



architecture Behavioral of filter is


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

type t_std_logic_2 is array (0 to 1) of STD_LOGIC;
type t_std_logic_vector8_2 is array (0 to 1) of STD_LOGIC_VECTOR(7 DOWNTO 0);
type t_std_logic_vector10_2 is array (0 to 1) of STD_LOGIC_VECTOR(9 DOWNTO 0);

signal din_s: t_std_logic_vector8_2;
signal wr_en_s: t_std_logic_2;
signal rd_en_s: t_std_logic_2;
signal prog_full_thresh_s: t_std_logic_vector10_2;
signal full_s: t_std_logic_2;
signal empty_s: t_std_logic_2;
signal prog_full_s: t_std_logic_2;


COMPONENT d_latch
  GENERIC (
        bus_width : integer := 8
    );
  PORT (
     D : in STD_LOGIC_VECTOR (bus_width - 1 downto 0);
     Q : out STD_LOGIC_VECTOR (bus_width - 1 downto 0);
     CLK : in STD_LOGIC;
     EN : in STD_LOGIC;
     RESET : in STD_LOGIC
  );
END COMPONENT;

type t_std_logic_3_3 is array (0 to 2, 0 to 2) of STD_LOGIC;
type t_std_logic_vector8_3_3 is array (0 to 2, 0 to 2) of STD_LOGIC_VECTOR(7 DOWNTO 0);

signal d_s: t_std_logic_vector8_3_3;
signal q_s: t_std_logic_vector8_3_3;
signal en_s: t_std_logic_3_3;

signal reset_fifos_and_latches: STD_LOGIC;
signal last_pixel_x: integer;
signal last_pixel_y: integer; 
signal height: integer;
signal width: integer;

begin

fifos:
    for i in 0 to 1 generate
        fifo_x: fifo
            PORT MAP ( clk              => clock,
                       rst              => reset_fifos_and_latches,
                       din              => q_s(2, i),
                       wr_en            => wr_en_s(i),
                       rd_en            => rd_en_s(i),
                       prog_full_thresh => prog_full_thresh_s(i),
                       dout             => d_s(0, i+1),
                       full             => full_s(i),
                       empty            => empty_s(i),
                       prog_full        => prog_full_s(i)
                     );
    end generate fifos;

latches_column:
    for i in 0 to 2 generate
       latches_line:
           for j in 0 to 2 generate
                latch_y: d_latch
                    PORT MAP ( D     => d_s(i, j),
                               Q     => q_s(i, j),
                               CLK   => clock,
                               EN    => en_s(i, j),
                               RESET => reset_fifos_and_latches
                             );
            end generate latches_line;
    end generate latches_column;
    
   

filtering_process: process(clock, reset)
begin
    if (reset = '1') then
        reset_fifos_and_latches <= '1';
        width <= 0;
        height <= 0;
        valid_output <= '0';
        data_output <= x"00";
        last_pixel_x <= 0;
        last_pixel_y <= 0;
    else
        if (clock'event and clock = '1') then
            if (enable = '0') then
                reset_fifos_and_latches <= '1';
                width <= 0;
                height <= 0;
                valid_output <= '0';
                data_output <= x"00";
                last_pixel_x <= 0;
                last_pixel_y <= 0;
            else
                reset_fifos_and_latches <= '0';
                if (last_pixel_x = 0 and last_pixel_y = 0) then
                    width <= to_integer(signed(image_width));
                    height <= to_integer(signed(image_height));
                elsif last_pixel_x < width - 1 then
                    last_pixel_x <= last_pixel_x + 1;
                else
                    last_pixel_x <= 0;
                    last_pixel_y <= last_pixel_y + 1;
            end if;
        end if;
    end if;
end process;


end Behavioral;
