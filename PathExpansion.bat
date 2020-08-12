@echo off
echo %%0                              %0
echo Drive %%~d0:                     %~d0%
echo Path without drive %%~p0:        %~p0%
echo Drive and path location %%~dp0%: %~dp0%
echo Path full %%~f0%:                %~f0%
echo Filename without suffix %%~n0%:  %~n0%
echo Suffix (incl. dot) %%~x0%:       %~x0%
echo Short name %%~s0%:               %~s0%
echo Attributes %%~a0%:               %~a0%
echo Last modification %%~t0%:        %~t0%
echo File size %%~z0%:                %~z0%