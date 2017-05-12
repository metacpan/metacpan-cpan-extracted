#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( Cls Cursor Title XYMax SetConsoleSize );
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
  # open DIG, "> t\\05.data" or die $!;
}
else {
  open DIG, "t\\05.data" or die $!;
  @dig = <DIG>;
  close DIG;
  chomp @dig;
}


sub comp {            # compare screendump MD5 digests
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
$npipe->Write("1..37\n");        # <== test plan

# ****************************** BEGIN TESTS

SetConsoleSize(80, 25);
my ($Xmax, $Ymax) = XYMax();


# ======== tests for \e[#J ED: Erase Display:

# test 01
print("\n\e[2J\n   Normal:\n\n");
print(" BLACK   \e[40;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" RED     \e[41;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" GREEN   \e[42;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" YELLOW  \e[43;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" BLUE    \e[44;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" MAGENTA \e[45;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" CYAN    \e[46;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" WHITE   \e[47;30m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n\n");
print("\n   Bold:\n\n");
print(" BLACK   \e[40;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" RED     \e[41;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" GREEN   \e[42;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" YELLOW  \e[43;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" BLUE    \e[44;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" MAGENTA \e[45;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" CYAN    \e[46;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" WHITE   \e[47;30;1m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
comp(1);

# test 02
print("\n\e[2J\n   Underlined:\n\n");
print(" BLACK   \e[40;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" RED     \e[41;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" GREEN   \e[42;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" YELLOW  \e[43;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" BLUE    \e[44;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" MAGENTA \e[45;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" CYAN    \e[46;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" WHITE   \e[47;30;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n\n");
print("\n   Underlined and Bold:\n\n");
print(" BLACK   \e[40;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" RED     \e[41;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" GREEN   \e[42;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" YELLOW  \e[43;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" BLUE    \e[44;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" MAGENTA \e[45;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" CYAN    \e[46;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
print(" WHITE   \e[47;30;1;4m black \e[31mred \e[32mgreen \e[33myellow \e[34mblue \e[35mmagenta \e[36mcyan \e[37mwhite \e[0m\n");
comp(1);

# test 03..10

foreach my $bg (40..47) {
  Cls;
  print "12\e[${bg}m345\e[${_}mabcde\e[1mBOLD\e[21mfghij\e[m67890\n" foreach(30..37);
  print "\n";
  comp(1);
}

# test 11..18

foreach my $bg (40..47) {
  Cls;
  print "12\e[${bg}m345\e[${_}mabcde\e[4mUNDERSCORE\e[24mfghij\e[m67890\n" foreach(30..37);
  print "\n";
  comp(1);
}

# test 19..26

foreach my $bg (40..47) {
  Cls;
  print "12\e[${bg}m345\e[${_}mabcde\e[7mREVERSE\e[27mfghij\e[m67890\n" foreach(30..37);
  print "\n";
  comp(1);
}

# test 27..34

foreach my $bg (40..47) {
  Cls;
  print "12\e[${bg}m345\e[${_}mabcde\e[8mCONCEALED\e[28mfghij\e[m67890\n" foreach(30..37);
  print "\n";
  comp(1);
}

# test 35

Cls;
print "\e[32;1mWriting in STDOUT\e[m\n";
open OUTCOPY, ">&STDOUT";
close STDOUT;
close STDERR;
select OUTCOPY;
$|=1;
print "\e[33;1mWriting in OUTCOPY\e[m\n";
comp(1);

# test 36

Cls;
my $r = 1;
foreach my $i (0..15) {
  my $b = $i;
  my $u = '';
  if ( $b >= 8 ) {
    $b -= 8;
    $u = '4;';
  }
  print "\e[m\n";
  $b += 40;
  foreach my $j (0..15) {
    my $f = $j;
    my $g = '';
    if ( $f >= 8 ) {
      $f -= 8;
      $g = '1;';
    }
    $f += 30;
    my $s = "\e[$f;$g$b;$u";
    chop $s;
    $s .= "mGlop\n";
    print "\e[m";
    print $s;
    my ($f2, $b2) = Win32::Console::ANSI::_GetConsoleColors();
    $r =0 if ( $i != $b2 or $j != $f2 );
  }
}
print "\e[m";
$n++;
$npipe->Read();
$npipe->Write($r ? "ok $n\n":"not ok $n\n");

# test 37

Cls;
$r = 1;
my ($f0, $b0) = Win32::Console::ANSI::_GetConsoleColors();
print "\e[33;45mGlop"; # change foreground & background color

print "\e[39m";   # reset foreground color
my ($f1, $b1) = Win32::Console::ANSI::_GetConsoleColors();
$r = 0 if $f1 != $f0;
print "\e[49m";   # reset background color
($f1, $b1) = Win32::Console::ANSI::_GetConsoleColors();
$r = 0 if $b1 != $b0;

$n++;
$npipe->Read();
$npipe->Write($r ? "ok $n\n":"not ok $n\n");

# ****************************** END TESTS

if ($save) {
  open DIG, "> t\\05.data" or die $!;
  local $, = "\n";
  print DIG @dig;
  close DIG;
}

$npipe->Read();
$npipe->Write("_OVER");
# $npipe->Close();

__END__