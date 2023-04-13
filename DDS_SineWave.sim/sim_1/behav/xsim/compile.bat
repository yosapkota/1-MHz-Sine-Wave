@echo off
REM ****************************************************************************
REM Vivado (TM) v2022.2.1 (64-bit)
REM
REM Filename    : compile.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for compiling the simulation design source files
REM
REM Generated by Vivado on Thu Apr 13 15:11:41 -0400 2023
REM SW Build 3719031 on Thu Dec  8 18:35:04 MST 2022
REM
REM IP Build 3718410 on Thu Dec  8 22:11:41 MST 2022
REM
REM usage: compile.bat
REM
REM ****************************************************************************
REM compile Verilog/System Verilog design sources
echo "xvlog --incr --relax -prj Main_Driver_vlog.prj"
call xvlog  --incr --relax -prj Main_Driver_vlog.prj -log xvlog.log
call type xvlog.log > compile.log
REM compile VHDL design sources
echo "xvhdl --incr --relax -prj Main_Driver_vhdl.prj"
call xvhdl  --incr --relax -prj Main_Driver_vhdl.prj -log xvhdl.log
call type xvhdl.log >> compile.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0