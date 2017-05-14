@echo off
call sdf -o -dmif %1
call mif2rtf -o %1.rtf %1.out
del %1.out
