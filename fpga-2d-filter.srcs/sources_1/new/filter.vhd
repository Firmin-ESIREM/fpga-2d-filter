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
  Port ( data_entry: IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel should be provided individually, line after line, on each clock rise, starting one clock rise after enable.
         data_output: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Each pixel of the provided image will be output individually, with a shift of { (width * 2) + 9 } clock cycles from the entry.
         valid_output: OUT STD_LOGIC;  -- This is set to 1 when the filter is currently outputing some valid pixels to the data_output bus.
         image_width: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         image_height: IN STD_LOGIC_VECTOR(9 DOWNTO 0);  -- This value is read when enable is activated, it is ignored passed that point.
         enable: IN STD_LOGIC;  -- This should be set to '1' when the image’s width and height are provided, and should not be set back to '0' before you have retreived the whole output image. It should be set back to '0' before proceeding with another image.
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
type t_std_logic_3 is array (0 to 2) of STD_LOGIC;
type t_std_logic_vector8_2 is array (0 to 1) of STD_LOGIC_VECTOR(7 DOWNTO 0);
type t_integer_3 is array (0 to 2) of integer;

signal prog_full_thresh_s: STD_LOGIC_VECTOR(9 DOWNTO 0);
signal prog_full_thresh_filfo: STD_LOGIC_VECTOR(9 DOWNTO 0);
signal full_s: t_std_logic_3;
signal empty_s: t_std_logic_3;
signal prog_full_s: t_std_logic_3;
signal enable_fifo: t_std_logic_3;
signal fifo_pixels_to_enter: t_integer_3;
signal fifo_pixels_to_exit: t_integer_3;
signal filfo_out: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal filfo_full: STD_LOGIC;


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

type t_std_logic_3_3 is array (0 to 3, 0 to 2) of STD_LOGIC;
type t_std_logic_vector8_3_3 is array (0 to 3, 0 to 2) of STD_LOGIC_VECTOR(7 DOWNTO 0);

signal d_s: t_std_logic_vector8_3_3;

signal reset_fifos_and_latches: STD_LOGIC;
signal last_pixel: integer;
signal height: integer;
signal width: integer;
signal pixels_to_enter: integer;
signal pixels_to_exit: integer;
signal pixels_to_finish: integer;
signal filtered_pixel: std_logic_vector(7 downto 0);
signal data_output_selection: std_logic_vector(7 downto 0);


signal filtering_lena: std_logic;
signal filtered_lena_going_out: std_logic;

begin

fifos:
    for i in 0 to 1 generate
        fifo_x: fifo
            PORT MAP ( clk              => clock,
                       rst              => reset_fifos_and_latches,
                       din              => d_s(3, i),
                       wr_en            => enable_fifo(i),
                       rd_en            => prog_full_s(i),
                       prog_full_thresh => prog_full_thresh_s,
                       dout             => d_s(0, i+1),
                       full             => full_s(i),
                       empty            => empty_s(i),
                       prog_full        => prog_full_s(i)
                     );
    end generate fifos;

filtered_fifo: fifo
    PORT MAP ( clk              => clock,
               rst              => reset_fifos_and_latches,
               din              => filtered_pixel,
               wr_en            => enable_fifo(2),
               rd_en            => prog_full_s(2),
               prog_full_thresh => prog_full_thresh_filfo,
               dout             => filfo_out,
               full             => full_s(2),
               empty            => empty_s(2),
               prog_full        => prog_full_s(2)
             );

latches_column:
    for i in 0 to 2 generate
       latches_line:
           for j in 0 to 2 generate
                latch_y: d_latch
                    PORT MAP ( D     => d_s(i, j),
                               Q     => d_s(i+1, j),
                               CLK   => clock,
                               EN    => enable,
                               RESET => reset_fifos_and_latches
                             );
            end generate latches_line;
    end generate latches_column;    
   

filfo_full_latch: d_latch
    GENERIC MAP ( bus_width => 1 )
    PORT MAP ( D(0)  => prog_full_s(2),
               Q(0)  => filfo_full,
               CLK   => clock,
               EN    => '1',
               RESET => reset_fifos_and_latches
             );


filtering_process: process(clock, reset)
variable sum: integer;
--variable sum: unsigned(10 downto 0);
begin
    if (reset = '1') then
        reset_fifos_and_latches <= '1';
        width <= 0;
        height <= 0;
        pixels_to_enter <= 0;
        pixels_to_exit <= 0;
        valid_output <= '0';
        last_pixel <= -1;
        enable_fifo(0) <= '0';
        enable_fifo(1) <= '0';
        data_output_selection <= (others => '0');
    else
        if (clock'event and clock = '1') then
            reset_fifos_and_latches <= '0';
            if (enable = '0') then
                data_output_selection <= (others => '0');
                width <= 0;
                height <= 0;
                pixels_to_enter <= 0;
                pixels_to_exit <= 0;
                valid_output <= '0';
                last_pixel <= -1;
                enable_fifo(0) <= '0';
                enable_fifo(1) <= '0';
                enable_fifo(2) <= '0';             
            else
                for i in 0 to 2 loop
                    if (last_pixel > fifo_pixels_to_enter(i) and last_pixel < fifo_pixels_to_exit(i)) then
                        enable_fifo(i) <= '1';
                    else
                        enable_fifo(i) <= '0';
                    end if;
                end loop;
                if (last_pixel = -1) then
                    width <= to_integer(signed(image_width));
                    height <= to_integer(signed(image_height));
                    pixels_to_enter <= to_integer(signed(image_width))*2 + 3;
                    fifo_pixels_to_enter(0) <= 1;
                    fifo_pixels_to_enter(1) <= to_integer(signed(image_width)) + 1;
                    fifo_pixels_to_enter(2) <= to_integer(signed(image_width))*2 + 6;    -- ICI LE SOUCI !!!
                    pixels_to_exit <= to_integer(signed(image_width)) * to_integer(signed(image_height));
                    pixels_to_finish <= (to_integer(signed(image_width)) * to_integer(signed(image_height))) + to_integer(signed(image_width))*2 + 3;
                    fifo_pixels_to_exit(0) <= (to_integer(signed(image_width)) * to_integer(signed(image_height))) + 2;
                    fifo_pixels_to_exit(1) <= (to_integer(signed(image_width)) * to_integer(signed(image_height))) + to_integer(signed(image_width)) + 5;
                    fifo_pixels_to_exit(2) <= to_integer(signed(image_width)) * to_integer(signed(image_height)) + 1;
                    prog_full_thresh_s <= std_logic_vector(unsigned(image_width) - 5);
                    prog_full_thresh_filfo <= std_logic_vector(unsigned(image_width) - 1);
                    enable_fifo(0) <= '0';
                    enable_fifo(1) <= '0';
                    enable_fifo(2) <= '0';
                    data_output_selection <= (others => '0');
                elsif last_pixel < pixels_to_enter then
                    -- entrée et circulation uniquement
                    for i in 0 to 2 loop
                        if (last_pixel > fifo_pixels_to_enter(i) and last_pixel < fifo_pixels_to_exit(i)) then
                            enable_fifo(i) <= '1';
                        else
                            enable_fifo(i) <= '0';
                        end if;
                    end loop;
                    data_output_selection <= (others => '0');
                elsif last_pixel < pixels_to_exit then
                    -- fonctionnement complet (entrée, circulation, traitement, sortie)
                    filtering_lena <= '1';
                    sum := 0;
                    for i in 0 to 2 loop
                        for j in 0 to 2 loop
                            if (i /= 1 or j /= 1) then
                                sum := sum + to_integer( unsigned(d_s(i, j)) );
                            end if;
                        end loop;
                    end loop;
                    
                    sum := (sum + 4) / 8;
                    
                    filtered_pixel <= std_logic_vector(to_unsigned(sum, 8));

                    for i in 0 to 2 loop
                        if (last_pixel > fifo_pixels_to_enter(i) and last_pixel < fifo_pixels_to_exit(i)) then
                            enable_fifo(i) <= '1';
                        else
                            enable_fifo(i) <= '0';
                        end if;
                    end loop;
                    
                    if filfo_full = '1' then
                        data_output_selection <= filfo_out;
                        filtered_lena_going_out <= '1';
                    else
                        data_output_selection <= d_s(3, 2);
                        filtered_lena_going_out <= '0';
                    end if;
                    
                    valid_output <= '1';
                elsif last_pixel < pixels_to_finish then
                    -- circulation et sortie uniquement
                    filtering_lena <= '0';
                    for i in 0 to 2 loop
                        if (last_pixel > fifo_pixels_to_enter(i) and last_pixel < fifo_pixels_to_exit(i)) then
                            enable_fifo(i) <= '1';
                        else
                            prog_full_thresh_s <= std_logic_vector(to_unsigned(0, 10));
                            prog_full_thresh_filfo <= std_logic_vector(to_unsigned(0, 10));
                            enable_fifo(i) <= '0';
                        end if;
                    end loop;
                    
                    if empty_s(2) = '0' then
                        data_output_selection <= filfo_out;
                        filtered_lena_going_out <= '1';
                    else
                        data_output_selection <= d_s(3, 2);
                        filtered_lena_going_out <= '0';
                    end if;
                    
                    valid_output <= '1';
                else
                    valid_output <= '0';
                end if;
                last_pixel <= last_pixel + 1;
            end if;
        end if;
    end if;
end process;


d_s(0, 0) <= data_entry;
data_output <= data_output_selection;



end Behavioral;
