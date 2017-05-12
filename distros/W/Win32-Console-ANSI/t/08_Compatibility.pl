#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Console::ANSI qw( Cls Cursor Title XYMax SetConsoleSize);
use Digest::MD5 qw(md5_hex);
use Term::ANSIColor;

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
  # open DIG, "> t\\08.data" or die $!;
}
else {
  open DIG, "t\\08.data" or die $!;
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
Cls;
my @colors = qw/ black red green yellow blue magenta cyan white /;

foreach my $fg (@colors) {
  print color 'on_'.$fg;
  foreach (@colors) {
    print color $_;
    print " abcdef ";
  }
print "\n", color 'reset';
}
print "\n";
foreach my $fg (@colors) {
  print color 'on_'.$fg;
  foreach (@colors) {
    print color "bold $_";
    print " abcdef ";
  }
print "\n", color 'reset';
}

# sleep 5 if $save;
comp(1);

# test 02
Cls;

foreach my $fg (@colors) {
  print color 'underline on_'.$fg;
  foreach (@colors) {
    print color $_;
    print " abcdef ";
  }
print "\n", color 'reset';
}
print "\n";
foreach my $fg (@colors) {
  print color 'underline bold on_'.$fg;
  foreach (@colors) {
    print color "bold $_";
    print " abcdef ";
  }
print "\n", color 'reset';
}

# sleep 5 if $save;
comp(1);

# test 03
Cls;

foreach my $fg (@colors) {
  print color 'underscore on_'.$fg;
  foreach (@colors) {
    print color $_;
    print " abcdef ";
  }
print "\n", color 'reset';
}
print "\n";
foreach my $fg (@colors) {
  print color 'underscore bold on_'.$fg;
  foreach (@colors) {
    print color "bold $_";
    print " abcdef ";
  }
print "\n", color 'reset';
}

# sleep 5 if $save;
comp(1);


# ****************************** END TESTS

if ($save) {
  open DIG, "> t\\08.data" or die $!;
  local $, = "\n";
  print DIG @dig;
  close DIG;
}

$npipe->Read();
$npipe->Write("_OVER");

__END__