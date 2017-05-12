@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl 
#line 15

=head1 NAME

This is a pretend script that we need to check

=head1 DESCRIPTION

This is a pod file without errors.

=head1 AUTHOR

Andy Lester, garbage-address@aol.com

=head1 COPYRIGHT

Copyright 2004, Andy Lester

=cut

__END__
:endofperl
