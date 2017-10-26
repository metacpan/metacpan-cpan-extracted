#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( Cursor Title XYMax Cls);

close STDOUT;                 # needed for Win9x
open STDOUT, '+> CONOUT$';
binmode STDOUT;
select STDOUT;
$|++;

Win32::Console::ANSI::_SetConsoleStandard();

my $npipe = new Win32::Pipe("\\\\.\\pipe\\ANSINamedPipe",1) or die $^E;
my $n;

sub ok {
  $n++;
  $npipe->Read();
  $npipe->Write($_[0] ? "ok $n\n":"not ok $n\n");
}

$npipe->Read();
$npipe->Write("1..98\n");        # <== test plan

# ****************************** BEGIN TESTS

my ($Xmax, $Ymax) = XYMax();
my ($Xoverflow, $Yoverflow) = ( ((1200 > $Xmax) ? 1200 : $Xmax+2), ((1000 > $Ymax) ? 1000 : $Ymax+2) );

# test 01
print "\e[2J";             # clear screen
my ($x, $y) = Cursor();
ok( $x==1 and $y==1 );   # origin

# ======== tests for \e[#A CUU: CUrsor Up

# test 02
Cursor(25, 12);
print "\e[A";
($x, $y) = Cursor();
ok( $x==25 and $y==11 );

# test 03
Cursor(25, 12);
print "\e[1A";
($x, $y) = Cursor();
ok( $x==25 and $y==11 );

# test 04
Cursor(25, 12);
print "\e[2A";
($x, $y) = Cursor();
ok( $x==25 and $y==10 );

# test 05
Cursor(25, 12);
print "\e[10A";
($x, $y) = Cursor();
ok( $x==25 and $y==2 );

# test 06
Cursor(25, 12);
print "\e[11A";
($x, $y) = Cursor();
ok( $x==25 and $y==1 );

# test 07
Cursor(25, 12);
print "\e[12A";
($x, $y) = Cursor();
ok( $x==25 and $y==1 );

# test 08
Cursor(25, 12);
print "\e[1000A";
($x, $y) = Cursor();
ok( $x==25 and $y==1 );

# test 09
Cursor(25, $Ymax);
print "\e[2A";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax-2 );

# test 10
Cursor(25, 1);
print "\e[2A";
($x, $y) = Cursor();
ok( $x==25 and $y==1 );

# test 11
Cursor(25, 12);
print "\e[0A";
($x, $y) = Cursor();
ok( $x==25 and $y==12 );

# ======== tests for \e[#B CUD: CUrsor Down

# test 12
Cursor(25, 12);
print "\e[B";
($x, $y) = Cursor();
ok( $x==25 and $y==13 );

# test 13
Cursor(25, 12);
print "\e[1B";
($x, $y) = Cursor();
ok( $x==25 and $y==13 );

# test 14
Cursor(25, 12);
print "\e[2B";
($x, $y) = Cursor();
ok( $x==25 and $y==14 );

# test 15
Cursor(25, 12);
print "\e[10B";
($x, $y) = Cursor();
ok( $x==25 and $y==22 );

# test 16
Cursor(25, $Ymax-3);
print "\e[2B";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax-1 );

# test 17
Cursor(25, $Ymax-3);
print "\e[3B";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax );

# test 18
Cursor(25, $Ymax-3);
print "\e[4B";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax );

# test 19
Cursor(25, $Ymax-3);
print "\e[1000B";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax );

# test 20
Cursor(25, $Ymax);
print "\e[2B";
($x, $y) = Cursor();
ok( $x==25 and $y==$Ymax );

# test 21
Cursor(25, 1);
print "\e[2B";
($x, $y) = Cursor();
ok( $x==25 and $y==3 );

# test 22
Cursor(25, 12);
print "\e[0B";
($x, $y) = Cursor();
ok( $x==25 and $y==12 );

# ======== tests for \e[#C CUF: CUrsor Forward

# test 23
Cursor(25, 12);
print "\e[1C";
($x, $y) = Cursor();
ok( $x==26 and $y==12 );

# test 24
Cursor(25, 12);
print "\e[C";
($x, $y) = Cursor();
ok( $x==26 and $y==12 );

# test 25
Cursor(25, 12);
print "\e[2C";
($x, $y) = Cursor();
ok( $x==27 and $y==12 );

# test 26
Cursor(1, 12);
print "\e[2C";
($x, $y) = Cursor();
ok( $x==3 and $y==12 );

# test 27
Cursor($Xmax-3, 12);
print "\e[2C";
($x, $y) = Cursor();
ok( $x==$Xmax-1 and $y==12 );

# test 28
Cursor($Xmax-3, 12);
print "\e[3C";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==12 );

# test 29
Cursor($Xmax-3, 12);
print "\e[4C";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==12 );

# test 30
Cursor($Xmax-3, 12);
print "\e[1000C";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==12 );

# test 31
Cursor(25, 12);
print "\e[0C";
($x, $y) = Cursor();
ok( $x==25 and $y==12 );

# ======== tests for \e[#D  CUB: CUrsor Backward

# test 32
Cursor(25, 12);
print "\e[1D";
($x, $y) = Cursor();
ok( $x==24 and $y==12 );

# test 33
Cursor(25, 12);
print "\e[D";
($x, $y) = Cursor();
ok( $x==24 and $y==12 );

# test 34
Cursor(25, 12);
print "\e[2D";
($x, $y) = Cursor();
ok( $x==23 and $y==12 );

# test 35
Cursor($Xmax, 12);
print "\e[2D";
($x, $y) = Cursor();
ok( $x==$Xmax-2 and $y==12 );

# test 36
Cursor(4, 12);
print "\e[2D";
($x, $y) = Cursor();
ok( $x==2 and $y==12 );

# test 37
Cursor(4, 12);
print "\e[3D";
($x, $y) = Cursor();
ok( $x==1 and $y==12 );

# test 38
Cursor(4, 12);
print "\e[4D";
($x, $y) = Cursor();
ok( $x==1 and $y==12 );

# test 39
Cursor(4, 12);
print "\e[1000D";
($x, $y) = Cursor();
ok( $x==1 and $y==12 );

# test 40
Cursor(4, 12);
print "\e[0D";
($x, $y) = Cursor();
ok( $x==4 and $y==12 );

# ======== tests for \e[#E CNL: Cursor Next Line

# test 41
Cursor(4, 12);
print "\e[1E";
($x, $y) = Cursor();
ok( $x==1 and $y==13 );

# test 42
Cursor(4, 12);
print "\e[E";
($x, $y) = Cursor();
ok( $x==1 and $y==13 );

# test 43
Cursor(4, 12);
print "\e[2E";
($x, $y) = Cursor();
ok( $x==1 and $y==14 );

# test 44
Cursor($Xmax, 12);
print "\e[3E";
($x, $y) = Cursor();
ok( $x==1 and $y==15 );

# test 45
Cursor(4, 12);
print "\e[2E";
($x, $y) = Cursor();
ok( $x==1 and $y==14 );

# test 46
Cursor(4, $Ymax-3);
print "\e[2E";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax-1 );

# test 47
Cursor(4, $Ymax-3);
print "\e[3E";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax );

# test 48
Cursor(4, $Ymax-3);
print "\e[4E";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax );

# test 49
Cursor(4, $Ymax-3);
print "\e[1000E";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax );

# test 50
Cursor(4, 12);
print "\e[0E";
($x, $y) = Cursor();
ok( $x==1 and $y==12 );

# ======== tests for \e[#F CPL: Cursor Preceding Line

# test 51
Cursor(4, 12);
print "\e[1F";
($x, $y) = Cursor();
ok( $x==1 and $y==11 );

# test 52
Cursor(4, 12);
print "\e[F";
($x, $y) = Cursor();
ok( $x==1 and $y==11 );

# test 53
Cursor(4, 12);
print "\e[2F";
($x, $y) = Cursor();
ok( $x==1 and $y==10 );

# test 54
Cursor(12, 4);
print "\e[2F";
($x, $y) = Cursor();
ok( $x==1 and $y==2 );

# test 55
Cursor(12, 4);
print "\e[3F";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 56
Cursor(12, 4);
print "\e[4F";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 57
Cursor(12, 4);
print "\e[1000F";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 58
Cursor(12, 4);
print "\e[0F";
($x, $y) = Cursor();
ok( $x==1 and $y==4 );

# ======== tests for \e[#G CHA: Cursor Horizontal Absolute

# test 59
Cursor(12, 4);
print "\e[17G";
($x, $y) = Cursor();
ok( $x==17 and $y==4 );

# test 60
Cursor(12, 4);
print "\e[1G";
($x, $y) = Cursor();
ok( $x==1 and $y==4 );

# test 61
Cursor(12, 4);
print "\e[G";
($x, $y) = Cursor();
ok( $x==1 and $y==4 );

# test 62
Cursor(12, 4);
$x=$Xmax+1;
print "\e[${x}G";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==4 );

# test 63
Cursor(12, 4);
print "\e[1000G";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==4 );

# test 64
Cursor(12, 4);
print "\e[0G";
($x, $y) = Cursor();
ok( $x==1 and $y==4 );

# ======== tests for \e[#H

# test 65
Cursor(12, 4);
print "\e[H";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 66
Cursor(12, 4);
print "\e[1H";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 67
Cursor(12, 4);
print "\e[3H";
($x, $y) = Cursor();
ok( $x==1 and $y==3 );

# test 68
Cursor(12, 4);
print "\e[0H";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 69
Cursor(12, 4);
print "\e[${Yoverflow}H";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax );

# test 70
Cursor(12, 4);
print "\e[;H";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 71
Cursor(12, 4);
print "\e[17;H";
($x, $y) = Cursor();
ok( $x==1 and $y==17 );

# test 72
Cursor(12, 4);
print "\e[;9H";
($x, $y) = Cursor();
ok( $x==9 and $y==1 );

# test 73
Cursor(12, 4);
print "\e[17;9H";
($x, $y) = Cursor();
ok( $x==9 and $y==17 );

# test 74
Cursor(12, 4);
print "\e[${Yoverflow};9H";
($x, $y) = Cursor();
ok( $x==9 and $y==$Ymax );

# test 75
Cursor(12, 4);
print "\e[17;${Xoverflow}H";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==17 );

# test 76
Cursor(12, 4);
print "\e[${Yoverflow};${Xoverflow}H";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==$Ymax );

# ======== tests for \e[#f

# test 77
Cursor(12, 4);
print "\e[f";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 78
Cursor(12, 4);
print "\e[1f";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 79
Cursor(12, 4);
print "\e[3f";
($x, $y) = Cursor();
ok( $x==1 and $y==3 );

# test 80
Cursor(12, 4);
print "\e[0f";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 81
Cursor(12, 4);
print "\e[${Yoverflow}f";
($x, $y) = Cursor();
ok( $x==1 and $y==$Ymax );

# test 82
Cursor(12, 4);
print "\e[;f";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 83
Cursor(12, 4);
print "\e[17;f";
($x, $y) = Cursor();
ok( $x==1 and $y==17 );

# test 84
Cursor(12, 4);
print "\e[;9f";
($x, $y) = Cursor();
ok( $x==9 and $y==1 );

# test 85
Cursor(12, 4);
print "\e[17;9f";
($x, $y) = Cursor();
ok( $x==9 and $y==17 );

# test 86
Cursor(12, 4);
print "\e[${Yoverflow};9f";
($x, $y) = Cursor();
ok( $x==9 and $y==$Ymax );

# test 87
Cursor(12, 4);
print "\e[17;${Xoverflow}f";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==17 );

# test 88
Cursor(12, 4);
print "\e[${Yoverflow};${Xoverflow}f";
($x, $y) = Cursor();
ok( $x==$Xmax and $y==$Ymax );

# ======== tests for \e[#s and \e[#u

# test 89
Cursor(12, 4);
print "\e[u";
($x, $y) = Cursor();
ok( $x==1 and $y==1 );

# test 90
Cursor(12, 4);
print "\e[s";
($x, $y) = Cursor();
ok( $x==12 and $y==4 );

# test 91
Cursor(27, 9);
($x, $y) = Cursor();
ok( $x==27 and $y==9 );

# test 92
print "\e[u";
($x, $y) = Cursor();
ok( $x==12 and $y==4 );

# ======== tests for \e[?25h and \e[?25l

# test 93
print "blahblah\e[?25hblahblah";
my $cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( $cursorstate );

# test 94
print "blahblah\e[?25lblahblah";
my $cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( !$cursorstate );

# test 95
print "blahblah\e[?25hblahblah";
$cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( $cursorstate );

# test 96
print "blahblah\e[?25kblahblah";
$cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( $cursorstate );

# test 97
print "blahblah\e\e\e[?25lblahblah";
$cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( !$cursorstate );

# test 98
print "blahblah\e\e\e[?26hblahblah";
$cursorstate = (Win32::Console::ANSI::_GetCursorInfo())[1];
ok( !$cursorstate );



# ====== END TESTS

$npipe->Read();
$npipe->Write("_OVER");

__END__
