#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( Cursor Title XYMax Cls ScriptCP CursorSize );

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
$npipe->Write("1..39\n");        # <== test plan

# ====== BEGIN TESTS

my ($Xmax, $Ymax) = XYMax();
my ($Xoverflow, $Yoverflow) = ( ((1200 > $Xmax) ? 1200 : $Xmax+2), ((1000 > $Ymax) ? 1000 : $Ymax+2) );

# ======== tests Cursor function

# test 01
Cls();
my ($x, $y) = Cursor();
my ($x1, $y1) = Cursor();
ok( $x==$x1 and $y==$y1 );


# test 02
print "\e[2J";             # clear screen
($x, $y) = Cursor();
ok( $x==1 and $y==1 );   # origin

# test 03
print "\n\n123456";
($x, $y) = Cursor();
ok( $x==7 and $y==3 );

# test 04
Cursor(17, 8);
($x, $y) = Cursor();
ok( $x==17 and $y==8 );

# test 05
Cursor($Xmax-1, 8);            # cursor max right
($x, $y) = Cursor();
ok( $x==$Xmax-1 and $y==8 );

# test 06
Cursor($Xmax   , 8);
($x, $y) = Cursor();
ok( $x==$Xmax and $y==8 );

# test 07
Cursor($Xmax+1, 8);
($x, $y) = Cursor();
ok( $x==$Xmax and $y==8 );

# test 08
Cursor(1000, 8);
($x, $y) = Cursor();
ok( $x==$Xmax and $y==8 );

# test 09
($x, $y) = Cursor(0, 0);    # don't move
ok( $x==$Xmax and $y==8 );

# test 10
Cursor(1, 8);            # cursor max left
($x, $y) = Cursor();
ok( $x==1 and $y==8 );

# test 11
Cursor(0, 8);
($x, $y) = Cursor();
ok( $x==1 and $y==8 );

# test 12
Cursor(-1, 8);
($x, $y) = Cursor();
ok( $x==1 and $y==8 );

# test 13
Cursor(-1000, 8);
($x, $y) = Cursor();
ok( $x==1 and $y==8 );

# test 14                # cursor max up
Cursor(17, 5);
($x, $y) = Cursor();
ok( $x==17 and $y==5 );

# test 15
Cursor(17, 1);
($x, $y) = Cursor();
ok( $x==17 and $y==1 );

# test 16
Cursor(17, 5);
Cursor(17, 0);
($x, $y) = Cursor();
ok( $x==17 and $y==5 );

# test 17
Cursor(17, -1);
($x, $y) = Cursor();
ok( $x==17 and $y==1 );

# test 18
Cursor(17, 5);
Cursor(17, -1000);
($x, $y) = Cursor();
ok( $x==17 and $y==1 );

# test 19                # cursor max down
Cursor(17, $Ymax-1);
($x, $y) = Cursor();
ok( $x==17 and $y==$Ymax-1 );

# test 20
Cursor(17, 5);
Cursor(17, $Ymax);
($x, $y) = Cursor();
ok( $x==17 and $y==$Ymax );

# test 21
Cursor(17, 5);
Cursor(17, $Ymax+1);
($x, $y) = Cursor();
ok( $x==17 and $y==$Ymax );

# test 22
Cursor(17, 5);
Cursor(17, $Yoverflow);
($x, $y) = Cursor();
ok( $x==17 and $y==$Ymax );

# test 23                # all max
Cursor(17, 5);
Cursor($Xoverflow, $Yoverflow);
($x, $y) = Cursor();
ok( $x==$Xmax and $y==$Ymax );

# ======== tests Title function

my $new_title1 = 'The console title number 1';
my $new_title2 = 'The console title number 2';

# test 24
Title($new_title1);
my $title = Title();
ok( $title eq $new_title1 );

# test 25
$title = Title();
ok( $title eq $new_title1 );

# test 26
$title = Title($new_title2);
ok( $title eq $new_title1 );

# test 27
$title = Title();
ok( $title eq $new_title2 );

# ======== tests ScriptCP function

# test 28
my $old_cp = ScriptCP();
my $cp = ScriptCP();
ok( $cp == $old_cp );

# test 29
ScriptCP(1250);
$cp = ScriptCP();
ok( $cp == 1250 );

ScriptCP($old_cp);

# ======== tests CursorSize function

# test 30
my $size1 = CursorSize();
my $size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size1 == $size2 );

# test 31
CursorSize(77);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size2 == 77 );

# test 32
CursorSize(0);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size2 == 1 );

# test 33
CursorSize(-5);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
print STDERR "\n$size2\n";
ok( $size2 == 1 );

# test 34
CursorSize(100);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size2 == 100 );

# test 35
CursorSize(101);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size2 == 100 );

# test 36
CursorSize(777);
$size2 = (Win32::Console::ANSI::_GetCursorInfo())[0];
ok( $size2 == 100 );

# test 37
CursorSize(82);
$size1 = CursorSize();
ok( $size1 == 82 );

# test 38
$size1 = CursorSize(56);
ok( $size1 == 82 );

# test 39
$size1 = CursorSize();
ok( $size1 == 56 );


# ====== END TESTS

$npipe->Read();
$npipe->Write("_OVER");

__END__
