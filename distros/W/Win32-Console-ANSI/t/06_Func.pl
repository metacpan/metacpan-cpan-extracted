#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( :all );

close STDOUT;                 # needed for Win9x
open STDOUT, '+> CONOUT$';
binmode STDOUT;
select STDOUT;
$|++;

Win32::Console::ANSI::_SetConsoleStandard();

my $npipe = new Win32::Pipe("\\\\.\\pipe\\ANSINamedPipe", 1) or die $^E;
my $n;

sub ok {
  $n++;
  $npipe->Read();
  $npipe->Write($_[0] ? "ok $n\n":"not ok $n\n");
}

$npipe->Read();
$npipe->Write("1..22\n");        # <== test plan

# ====== BEGIN TESTS

# ======== tests ShowConsoleWindow function

# test 01
ok( ShowConsoleWindow(SW_HIDE) );

# test 02
ok( 0 == ShowConsoleWindow(SW_MAXIMIZE) );

# test 03
ok( ShowConsoleWindow(SW_MAXIMIZE) );

# test 04
ok( ShowConsoleWindow(SW_MINIMIZE) );

# test 05
ok( ShowConsoleWindow(SW_RESTORE) );

# test 06
ok( ShowConsoleWindow(SW_SHOW) );

# test 07
ok( ShowConsoleWindow(SW_SHOWDEFAULT) );

# test 08
ok( ShowConsoleWindow(SW_SHOWMAXIMIZED) );

# test 09
ok( ShowConsoleWindow(SW_SHOWMINIMIZED) );

# test 10
ok( ShowConsoleWindow(SW_SHOWMINNOACTIVE) );

# test 11
ok( ShowConsoleWindow(SW_SHOWNA) );

# test 12
ok( ShowConsoleWindow(SW_SHOWNOACTIVATE) );

# test 13
ok( ShowConsoleWindow(SW_NORMAL) );

# ======== tests SetCloseButton function

# test 14
ok( SetCloseButton( 1 ) );

# test 15
ok( SetCloseButton( 0 ) );

# test 16
ok( SetCloseButton( 0 ) );

# test 17
ok( SetCloseButton( 1 ) );

# test 18
ok( SetCloseButton( 1 ) );

# ======== tests SetMonitorState function

# test 19
SetMonitorState( MS_ON );
ok(1);

# test 20
ok( MS_STANDBY ); # existence only

# test 21
ok( MS_OFF );     # existence only

# ======== tests SetConsoleFullScreen function

# test 22
if ( SetConsoleFullScreen(1) ) {
  Cls;
  my ($Xmax, $Ymax) = XYMax();

  my $msg = "FULL-SCREEN MODE TEST";
  my $x = int(($Xmax - length $msg)/2);
  print "\e[33;1m\e[5;${x}H$msg\e[m";

  $msg = "Don't panic.";
  $x = int (($Xmax - length $msg)/2);
  print "\e[32;1m\e[7;${x}H$msg\e[m\n\n";

  sleep 5;

  SetConsoleFullScreen(0)
}

ok(1);

# ====== END TESTS

$npipe->Read();
$npipe->Write("_OVER");

__END__