-- File designed by Julien Dubois

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_lena_dupliq is
       
end;

architecture arch_tb_lena_dupliq of tb_lena_dupliq is


  signal I1 : std_logic_vector (7 downto 0);
  signal CLK : std_logic;
  signal O1 : std_logic_vector (7 downto 0); 
  signal DATA_AVAILABLE : std_logic;
  
begin
 p_read : process
  FILE vectors : text;
  variable Iline : line;
  variable I1_var :std_logic_vector (7 downto 0);
 
    begin
	DATA_AVAILABLE <= '0';
	wait for 20 ns;
    file_open (vectors,"Lena128x128g_8bits.dat", read_mode);
    
    while not endfile(vectors) loop
      readline (vectors,Iline);
      read (Iline,I1_var);
                
      I1 <= I1_var;
	  DATA_AVAILABLE <= '1';
	  wait for 10 ns;
    end loop;
    DATA_AVAILABLE <= '0';
    wait for 10 ns;
    file_close (vectors);
    wait;
 end process;

p_write: process
  file results : text;
  variable OLine : line;
  variable O1_var :std_logic_vector (7 downto 0);
    
    begin
    file_open (results,"Lena128x128g_8bits_r.dat", write_mode);
    wait for 10 ns;
    wait until DATA_AVAILABLE = '1';
    
    wait for 10 ns;

    while DATA_AVAILABLE ='1' loop
      write (Oline, O1, right, 2);
      writeline (results, Oline);
      wait for 10 ns;  
    end loop;
    file_close (results);
    wait;
 end process;
--Instancier composant filtre à place de la simple recopie entre I1 vers sortie O1 (top)
O1 <= I1;
  
end arch_tb_lena_dupliq;

