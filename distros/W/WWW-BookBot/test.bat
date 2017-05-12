@if not "%1"=="" goto ok
@echo Usage: test.bat botalias
@goto finish

: ok
@if exist result rd /S /Q result
@if not exist Makefile perl Makefile.PL
@nmake /C > NUL
@perl -Mblib bin\bookbot --bot=%1 --work_dir=result %2 %3 %4 %5 %6 %7 %8
@dir result
@goto finish

: finish