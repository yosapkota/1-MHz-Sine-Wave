----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/12/2023 11:02:39 AM
-- Design Name: 
-- Module Name: Main_Driver - Behavioral
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

entity Main_Driver is
  Port ( SW 			: in  STD_LOGIC_VECTOR (3 downto 0);
           --BTN 			: in  STD_LOGIC_VECTOR (3 downto 0);
           CLK 			: in  STD_LOGIC;
           
           JD1           : buffer  std_logic_vector(4 DOWNTO 1);
           JD2           : buffer  std_logic_vector(10 DOWNTO 7);
           
           JC1           : buffer  std_logic_vector(4 DOWNTO 1);
           JC2           : buffer  std_logic_vector(10 DOWNTO 7);           
           
           LED 			: out  STD_LOGIC_VECTOR (3 downto 0)
        );
end Main_Driver;

architecture Behavioral of Main_Driver is
component DDS_SineWave 
  port (
    pwm_clk       : in  std_logic;
    reset     : in  std_logic;
    frequency : in  unsigned(31 downto 0);
    sine_out  : buffer unsigned(7 downto 0); -- out
    PWM_Hi_Output : out std_logic;
    PWM_Lo_Output : out std_logic;
    PWM_U_High : out std_logic;
    PWM_V_High : out std_logic;
    PWM_W_High : out std_logic
    );
end component;

component clk_wiz_0
     port(
     clk_in1 : in STD_LOGIC;
     clk_out1 : out STD_LOGIC
     );
end component;
signal PWM_Hi_Out : STD_LOGIC := '0';
signal PWM_Lo_Out : STD_LOGIC:= '0';
signal clk_400MHz : STD_LOGIC;
signal clk_sw : STD_LOGIC;

signal PWM_U_High_Out : std_logic;
signal PWM_V_High_Out :  std_logic;
signal PWM_W_High_Out :  std_logic;

begin

CLK_PORT_MAP : clk_wiz_0 port map(
    clk_in1 => clk,
    clk_out1 => clk_400MHz
);

PWM_OUT : DDS_SineWave port map(
     pwm_clk => clk_400MHz,
     reset => '0',
     frequency => x"00000000",
     --sine_out => x"00",
     PWM_Hi_output => PWM_Hi_Out,
     PWM_Lo_output => PWM_Lo_Out,
     PWM_U_High => PWM_U_High_Out,
     PWM_V_High => PWM_V_High_Out,
     PWM_W_High => PWM_W_High_Out
     
);

JD1(1) <= PWM_Hi_Out;
JD1(2) <= PWM_V_High_Out;
JD1(3) <= PWM_W_High_Out;

JD2(7) <= PWM_lo_Out;

clk_sw <= clk_400MHZ and sw(0);
-- JD1(2) <= clk;


end Behavioral;
