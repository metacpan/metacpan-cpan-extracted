@echo off
call sdf -o -dmif -thlp %1
call mif2rtf -m help -o %1.rtf %1.out
del %1.out
