library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DDS_SineWave is
  port (
    pwm_clk       : in  std_logic;
    reset     : in  std_logic;
    frequency : in  unsigned(31 downto 0);
    sine_out  : buffer unsigned(7 downto 0);
    PWM_Hi_Output : out std_logic;
    PWM_Lo_Output : out std_logic;
    PWM_U_High : out std_logic;
    PWM_V_High : out std_logic;
    PWM_W_High : out std_logic
  );
end entity DDS_SineWave;

architecture Behavioral of DDS_SineWave is
  constant LUT_SIZE      : integer := 256;
  type lut_type is array (0 to LUT_SIZE-1) of unsigned(7 downto 0);  -- signed
  constant lookup_table    : lut_type := ( 
    x"80",x"83",x"86",x"89",x"8c",x"8f",x"92",x"95",
    x"98",x"9b",x"9e",x"a2",x"a5",x"a7",x"aa",x"ad",
    x"b0",x"b3",x"b6",x"b9",x"bc",x"be",x"c1",x"c4",
    x"c6",x"c9",x"cb",x"ce",x"d0",x"d3",x"d5",x"d7",
    x"da",x"dc",x"de",x"e0",x"e2",x"e4",x"e6",x"e8",
    x"ea",x"eb",x"ed",x"ee",x"f0",x"f1",x"f3",x"f4",
    x"f5",x"f6",x"f8",x"f9",x"fa",x"fa",x"fb",x"fc",
    x"fd",x"fd",x"fe",x"fe",x"fe",x"ff",x"ff",x"ff",
    x"ff",x"ff",x"ff",x"ff",x"fe",x"fe",x"fe",x"fd",
    x"fd",x"fc",x"fb",x"fa",x"fa",x"f9",x"f8",x"f6",
    x"f5",x"f4",x"f3",x"f1",x"f0",x"ee",x"ed",x"eb",
    x"ea",x"e8",x"e6",x"e4",x"e2",x"e0",x"de",x"dc",
    x"da",x"d7",x"d5",x"d3",x"d0",x"ce",x"cb",x"c9",
    x"c6",x"c4",x"c1",x"be",x"bc",x"b9",x"b6",x"b3",
    x"b0",x"ad",x"aa",x"a7",x"a5",x"a2",x"9e",x"9b",
    x"98",x"95",x"92",x"8f",x"8c",x"89",x"86",x"83",
    x"80",x"7c",x"79",x"76",x"73",x"70",x"6d",x"6a",
    x"67",x"64",x"61",x"5d",x"5a",x"58",x"55",x"52",
    x"4f",x"4c",x"49",x"46",x"43",x"41",x"3e",x"3b",
    x"39",x"36",x"34",x"31",x"2f",x"2c",x"2a",x"28",
    x"25",x"23",x"21",x"1f",x"1d",x"1b",x"19",x"17",
    x"15",x"14",x"12",x"11",x"0f",x"0e",x"0c",x"0b",
    x"0a",x"09",x"07",x"06",x"05",x"05",x"04",x"03",
    x"02",x"02",x"01",x"01",x"01",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"02",
    x"02",x"03",x"04",x"05",x"05",x"06",x"07",x"09",
    x"0a",x"0b",x"0c",x"0e",x"0f",x"11",x"12",x"14",
    x"15",x"17",x"19",x"1b",x"1d",x"1f",x"21",x"23",
    x"25",x"28",x"2a",x"2c",x"2f",x"31",x"34",x"36",
    x"39",x"3b",x"3e",x"41",x"43",x"46",x"49",x"4c",
    x"4f",x"52",x"55",x"58",x"5a",x"5d",x"61",x"64",
    x"67",x"6a",x"6d",x"70",x"73",x"76",x"79",x"7c"
  );
  
    -- index update for three phase sine wave
  
  signal sine_u_idx : unsigned(7 downto 0) := (others => '0');
  signal sine_v_idx : unsigned(7 downto 0) := x"55";
  signal sine_w_idx : unsigned(7 downto 0) := x"AA";
  
  -- phase accumulator for three phases
  signal phase_accumulator : unsigned(31 downto 0) := (others => '0');
  signal phase_U_accumulator : unsigned(31 downto 0) := (others => '0');
  signal phase_V_accumulator : unsigned(31 downto 0) := x"4CCCCCB0";
  signal phase_W_accumulator : unsigned(31 downto 0) := x"99999960";
  
  ------------------------------------------------------------
  -- f_out = (f_clk * phase_increment)/2^no_of_bits_phase_accum
  ------------------------------------------------------------
  signal phase_increment  : unsigned(31 downto 0) := x"00A3D70A"; --x"0010624D"; -- 42949 for 1 kHz -- 4994967 for 100 kHz
  -- 1,073,741 100 Khz for 400 Mhz clk
  signal sine_idx       : unsigned(7 downto 0) := (others => '0');
  signal sine_modulated : unsigned(7 downto 0);
  signal sine_value_store : unsigned (7 downto 0);
  
  -- reference sine signal
  signal sine_u_phase : unsigned (7 downto 0); 
  signal sine_v_phase : unsigned (7 downto 0); 
  signal sine_w_phase : unsigned (7 downto 0); 
  
  
  -- triangular wave counter direction flag
  signal up : std_logic := '1';
  signal down : std_logic := '0';
  signal hold_count : std_logic_vector(3 downto 0) := (others => '0');
  signal count : std_logic_vector(7 downto 0) := (others => '0');
  
  -- three phase pulses
  signal PWM_High_Tmp : std_logic := '0';
  signal PWM_High : std_logic := '0';
  signal PWM_Low : std_logic := '0';
  
  signal PWM_U_High_Tmp : std_logic := '0';
  signal PWM_V_High_Tmp : std_logic := '0';
  signal PWM_W_High_Tmp : std_logic := '0';
  
  
  --- Dead Time inclusion---
  constant n : positive := 100; -- 1 us DT with n = 100 for 100 MHz
  signal PWM_U_Phase_delay_tmp : std_ulogic_vector(0 to n-1);
  
  
begin

  sine_out <= lookup_table(to_integer(unsigned(sine_idx))); -- lookup_table(to_integer(unsigned(sine_idx)));
  sine_value_store <= lookup_table(to_integer(unsigned(sine_idx)));
--  sine_modulated <= 5 * sine_value_store;

    sine_u_phase <= lookup_table(to_integer(unsigned(sine_u_idx)));
    sine_v_phase <= lookup_table(to_integer(unsigned(sine_v_idx)));
    sine_w_phase <= lookup_table(to_integer(unsigned(sine_w_idx)));

  Sine_Gen: process (pwm_clk, reset)
  begin
    if reset = '1' then
      phase_accumulator <= (others => '0');
      phase_increment  <= (others => '0');
      sine_idx <= (others => '0');
      
      phase_U_accumulator <= (others => '0');
      --phase_V_accumulator <= x"00000055";
      --phase_W_accumulator <= x"000000AA";
      
      sine_u_idx <= (others => '0');
      sine_v_idx <= x"55";
      sine_w_idx <= x"AA";
      
    elsif rising_edge(pwm_clk) then
    
      phase_accumulator <= phase_accumulator + phase_increment;
      
      phase_U_accumulator <= phase_U_accumulator + phase_increment;
      phase_V_accumulator <= phase_V_accumulator + phase_increment;
      phase_W_accumulator <= phase_W_accumulator + phase_increment;
      
      sine_idx <= phase_accumulator(31 downto 24);
      
      sine_u_idx <= phase_accumulator(31 downto 24);
      
      -- if(sine_v_idx > x"FF") then
      --      sine_v_idx <= (others => '0');
      -- else 
            sine_v_idx <= phase_V_accumulator(31 downto 24);
      -- end if;
      
      -- if(sine_w_idx > x"FF") then
      --      sine_w_idx <= (others => '0');
      -- else 
            sine_w_idx <= phase_W_accumulator(31 downto 24);
      -- end if;   
    end if;
  end process;
  
  -- sine amplitude from 0 to 255 
  -- up-down counter for a 20 kHz triangular wave 
  -- 50 us time, 50/10 *10^3 = 5000 counts , resets every 5k counts 
  -- 2500 upcount upto 255 and 2500 downcount to 0 from 255 
  
  
  -- 10 MHz counter for 100K sine wave kHz , remove hold count for 800 kHz triangular wave
  Triangle_Gen : process(pwm_clk)
  begin
  if(rising_edge(pwm_clk)) then
    -- hold_count <= hold_count + 1;
    -- if(hold_count >= 9) then
        if(up = '1') then
            count <= count + 15;
            if(count >= x"F0" )then
                up <= '0';
            end if;
        else 
            count <= count - 15;
            if(count <= x"0F") then   -- bit overflow in std_logic_vector
                up <= '1';
            end if;
        end if;
       -- hold_count <= x"0";
  --  end if;   
  end if;
     
  end process;
  
   Dead_Time : process (pwm_clk)
    begin
        if rising_edge (pwm_clk) then
            PWM_U_Phase_delay_tmp <= PWM_High_tmp & PWM_U_Phase_delay_tmp(0 to n-2);          
        end if;
    end process; 
    
  PWM_Gen: process(pwm_clk)
  begin
  
  if(rising_edge(pwm_clk)) then
    if(sine_u_phase > unsigned(count)) then
        PWM_High_tmp <= '1';
    else
        PWM_High_tmp <= '0';
    end if;
    
    if(sine_v_phase > unsigned(count)) then
        PWM_V_High_Tmp <= '1';
    else
        PWM_V_High_Tmp <= '0';
    end if;
    
    if(sine_w_phase > unsigned(count)) then
        PWM_W_High_Tmp <= '1';
    else
        PWM_W_High_Tmp <= '0';
    end if;
    
  end if;
  
  end process;
  
-- Sine_Index : process(pwm_clk)
--  begin
--    if(rising_edge(pwm_clk)) then
--        if(sine_v_idx >= x"FF") then
--            sine_v_idx <= (others => '0');
--        end if;
--    end if;
--  end process;

PWM_Hi_Output <= PWM_High_tmp; -- and PWM_U_Phase_delay_tmp(n-1);
PWM_Lo_Output <= not (PWM_High_tmp); -- or PWM_U_Phase_delay_tmp(n-1));

PWM_U_High <= PWM_High_tmp;
PWM_V_High <= PWM_V_High_Tmp;
PWM_W_High <= PWM_W_High_Tmp;

end architecture Behavioral;
 