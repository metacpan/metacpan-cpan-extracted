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
  # open DIG, "> t\\07.data" or die $!;
}
else {
  open DIG, "t\\07.data" or die $!;
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
$npipe->Write("1..3\n");        # <================= test plan

# ****************************** BEGIN TESTS

SetConsoleSize(80, 25);
my ($Xmax, $Ymax) = XYMax();


# ======== tests for \e[#J ED: Erase Display:

# test 01
Cls();
print "(01)-1234567890\e1234567890\n";
print "(02)-1234567890\e\e1234567890\n";
print "(03)-1234567890\e\e\e1234567890\n";
print "(04)-1234567890\e\e\e\e1234567890\n";
print "\n";
print "(05)-1234567890\e[1234567890\n";
print "(06)-1234567890\e[\e[1234567890\n";
print "(07)-1234567890\e[\e[\e[1234567890\n";
print "(08)-1234567890\e[\e[\e[\e[1234567890\n";

for(my $i=10; $i<20; $i++) {
  my $esc = "$i = \e[1;".('32;'x$i).'33m';
  print "$esc abcdefghijklm\e[m\n";
}

print "\e[1;".('32;'x1000).'33m'."abcdefghijklm\e[m\n";
print "\e[1;".('32;'x10000).'34m'."abcdefghijklm\e[m\n";

comp(1);

# test 02
Cls;

print '1234567890';
print "\e[5J";
print "abcdefghij\n";

print '1234567890';
print "\e[12345678J";
print "abcdefghij\n";

print '1234567890';
print "\e[1;2J";
print "abcdefghij\n";

print '1234567890';
print "\e[5K";
print "abcdefghij\n";

print '1234567890';
print "\e[1;2K";
print "abcdefghij\n";

print '1234567890';
print "\e[12345678K";
print "abcdefghij\n";

comp(1);

# test 03

Cls;

$s = "1234567890\x0D\x0Aabcdefghij";  # \r\n
print $s, "\n\n";

$s = "1234567890\x0Aabcdefghij";      # \n
print $s, "\n\n";

$s = "1234567890\x0Dabcdefghij";      # \r
print $s, "\n\n";

$s = "1234567890\x0A\x0Dabcdefghij";  # \r\n
print $s, "\n\n";
comp(1);

# ****************************** END TESTS

if ($save) {
  open DIG, "> t\\07.data" or die $!;
  local $, = "\n";
  print DIG @dig;
  close DIG;
}

$npipe->Read();
$npipe->Write("_OVER");

__END__