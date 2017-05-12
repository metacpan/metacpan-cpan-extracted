@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!/usr/local/bin/perl -w
#line 14
#
# tklock - an xlock-like program primarily for AFS-land.
#
# Stephen.O.Lidie@Lehigh.EDU, Lehigh University Computing Center.  98/09/13
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

use Tk '800.000';
use Tk::LockDisplay;
use subs qw/check_pw/;
use strict;

my $mw = MainWindow->new(qw/-width 1 -height 1/);
$mw->withdraw;
my $animation = $ARGV[0];
$animation ||= 'lines';
my $ld = $mw->LockDisplay(-authenticate => \&check_pw, -debug => 0, -animation => $animation);
$ld->Lock;
MainLoop;

sub check_pw {

    # Perform AFS validation unless on Win32.

    my($user, $pw) = @_;

    if ($^O eq 'MSWin32') {
	($pw eq $^O) ? exit(0) : return(0);
    } else {
	system "/usr/afsws/bin/klog $user " . quotemeta($pw) . " 2> /dev/null";
	($? == 0) ? exit(0) : return(0);
    }

} # end check_pw
__END__
:endofperl
