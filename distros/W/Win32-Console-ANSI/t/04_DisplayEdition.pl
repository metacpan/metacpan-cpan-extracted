#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( Cls Cursor Title XYMax SetConsoleSize);
use Digest::MD5 qw(md5_hex);

close STDOUT;                 # needed for Win9x
open STDOUT, '+> CONOUT$';
binmode STDOUT;
select STDOUT;
$|++;

Win32::Console::ANSI::_SetConsoleStandard();

my $npipe = new Win32::Pipe("\\\\.\\pipe\\ANSINamedPipe", 1) or die $^E;
my $n;
my $s;
my $dig;
my @dig;
my $save = 0;

if ($save) {
  # open DIG, "> t\\04.data" or die $!;
}
else {
  open DIG, "t\\04.data" or die $!;
  @dig = <DIG>;
  close DIG;
  chomp @dig;
}

sub skipped {
  ++$n;
  $npipe->Read();
  $npipe->Write("ok $n # skip");
}

sub comp {
  my $skip = shift;
  ++$n;
  my $digest = md5_hex(Win32::Console::ANSI::_ScreenDump());
  if ($save) {
    if ( $skip) {
      push @dig, $digest;
      return;
    }
    if ( <STDIN> eq "\n" ) {
      push @dig, $digest;
    }
    else {
      push @dig, "__ $n";
    }
  }
  else {
    $npipe->Read();
    $npipe->Write($digest eq $dig[$n-1] ? "ok $n\n":"not ok $n\n");
  }
}

$npipe->Read();
$npipe->Write("1..74\n");        # <== test plan

# ****************************** BEGIN TESTS

SetConsoleSize(80, 25);
my ($Xmax, $Ymax) = XYMax();

# ======== tests for \e[#J ED: Erase Display:

# test 01                              Cursor (25, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[0J";
comp(1);

# test 02
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[J";
comp(1);

# test 03
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[1J";
comp(1);

# test 04
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[2J";
comp(1);

# test 05                              Cursor (1, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[0J";
comp(1);

# test 06
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[1J";
comp(1);

# test 07
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[2J";
comp(1);

# test 08                              Cursor (80, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[0J";
comp(1);

# test 09
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[1J";
comp(1);

# test 10
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[2J";
comp(1);

# test 11                              Cursor (1, 1)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[0J";
comp(1);

# test 12
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[1J";
comp(1);

# test 13
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[2J";
comp(1);

# test 14                              Cursor (80, 25)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[0J";
comp(1);

# test 15
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[1J";
comp(1);

# test 16
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[2J";
comp(1);

# ======== tests for \e[#K EL: Erase Line

# test 17                              Cursor (25, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[0K";
comp(1);

# test 18
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[K";
comp(1);

# test 19
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[1K";
comp(1);

# test 20
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(25, 12);
# sleep 5 if $save;
print "\e[2K";
comp(1);

# test 21                              Cursor (1, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[0K";
comp(1);

# test 22
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[1K";
comp(1);

# test 23
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 12);
# sleep 5 if $save;
print "\e[2K";
comp(1);

# test 24                              Cursor (80, 12)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[0K";
comp(1);

# test 25
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[1K";
comp(1);

# test 26
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[2K";
comp(1);

# test 27                              Cursor (1, 1)
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[0K";
comp(1);

# test 28
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[1K";
comp(1);

# test 29
print "\e[2J";             # clear screen
print '*'x(25*80);
Cursor(1, 1);
# sleep 5 if $save;
print "\e[2K";
comp(1);

# test 30                              Cursor (80, 25)
print "\e[2J";             # clear screen
print '*'x(25*80-1);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[0K";
comp(1);

# test 31
print "\e[2J";             # clear screen
print '*'x(25*80-1);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[1K";
comp(1);

# test 32
print "\e[2J";             # clear screen
print '*'x(25*80-1);
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[2K";
comp(1);

# ======== tests for \e[#L IL: Insert Lines

# test 33                              Cursor (25, 12)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[1L";
comp(1);

# test 34
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[L";
comp(1);

# test 35
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[0L";
comp(1);

# test 36
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[5L";
comp(1);

# test 37                              Cursor (25, 1)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 1);
# sleep 5 if $save;
print "\e[3L";
comp(1);

# test 38                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[3L";
comp(1);

# test 39
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax);
# sleep 5 if $save;
print "\e[3L";
comp(1);

# test 40                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[1000L";
comp(1);

# ======== tests for \e[#M DL: Delete Line

# test 41                              Cursor (25, 12)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[1M";
comp(1);

# test 42
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[M";
comp(1);

# test 43
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[0M";
comp(1);

# test 44                              Cursor (25, 1)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(25, 1);
# sleep 5 if $save;
print "\e[2M";
comp(1);

# test 45                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[0M";
comp(1);

# test 46                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[1M";
comp(1);

# test 47                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[2M";
comp(1);

# test 48                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[3M";
comp(1);

# test 49                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[4M";
comp(1);

# test 50                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax-2);
# sleep 5 if $save;
print "\e[1000M";
comp(1);

# test 51                              Cursor (13, 25)
print "\e[2J";             # clear screen
print chr(65+$_)x80 for (0..23);
print 'Y'x79;
Cursor(13, $Ymax);
# sleep 5 if $save;
print "\e[1M";
comp(1);

# ======== tests for \e#@ ICH: Insert CHaracter

# test 52                              Cursor (25, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[1@";
comp(1);

# test 53                              Cursor (25, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(25, 12);
sleep 5 if $save;
print "\e[@";
comp(1);

# test 54                              Cursor (25, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(25, 12);
# sleep 5 if $save;
print "\e[0@";
comp(1);

# test 55                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[39@";
comp(1);

# test 56                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[40@";
comp(1);

# test 57                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[41@";
comp(1);

# test 58                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[1000@";
comp(1);

# test 59                              Cursor (79, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-1, 12);
# sleep 5 if $save;
print "\e[1@";
comp(1);

# test 60                              Cursor (80, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax, 12);
# sleep 5 if $save;
print "\e[1@";
comp(1);

# test 61                              Cursor (80, 25)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax, $Ymax);
# sleep 5 if $save;
print "\e[1@";
comp(1);

# ======== tests for \e[#P DCH: Delete CHaracter

# test 62                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[1P";
comp(1);

# test 63                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[P";
comp(1);

# test 64                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[0P";
comp(1);

# test 65                              Cursor (40, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(40, 12);
# sleep 5 if $save;
print "\e[25P";
comp(1);

# test 66                              Cursor (78, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-2, 12);
# sleep 5 if $save;
print "\e[1P";
comp(1);

# test 67                              Cursor (78, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-2, 12);
# sleep 5 if $save;
print "\e[2P";
comp(1);

# test 68                              Cursor (78, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-2, 12);
# sleep 5 if $save;
print "\e[3P";
comp(1);

# test 69                              Cursor (78, 12)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-2, 12);
# sleep 5 if $save;
print "\e[1000P";
comp(1);

# test 70                              Cursor (78, 25)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor($Xmax-2, $Ymax);
# sleep 5 if $save;
print "\e[1P";
comp(1);

# ======== tests for \n (comparison Win9x/WinNT)

# test 71                              Cursor (24, 5)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(24, 5);
# sleep 5 if $save;
print "\n";
comp(1);

# test 72                              Cursor (24, 25)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(24, $Ymax);
# sleep 5 if $save;
print "\n";
comp(1);

# test 73                              Cursor (24, 25)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(24, $Ymax);
# sleep 5 if $save;
print "\n\n\n";
comp(1);

# test 74                              Cursor (24, 25)
print "\e[2J";             # clear screen
print '1234567890'x8 for (0..23);
print '-'x79;
Cursor(24, $Ymax);
# sleep 5 if $save;
print "\n"x($Ymax-1);
comp(1);



# ****************************** END TESTS

if ($save) {
  open DIG, "> t\\04.data" or die $!;
  local $, = "\n";
  print DIG @dig;
  close DIG;
}

$npipe->Read();
$npipe->Write("_OVER");

__END__