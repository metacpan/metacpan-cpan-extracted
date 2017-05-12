#!/usr/bin/perl -w
#vim: syntax=perl
use strict;
use warnings;

use Test::More tests => 9;

ok(!&t1, '');
ok(&t2, '');
ok(!&t3, '');
ok(!&t4, '');
ok(!&t5, '');
ok(&t6, '');
ok(!&t7, '');
ok(&t8, '');
ok(&t9, '');

# ------------------------------------------------------------------------------
# t1 - Does not abort
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 10
# ------------------------------------------------------------------------------

sub t1 {
  no warnings 'closure';  # allows one test case to setup subroutines for 
                          # subsequent tests.
  my $result = eval {
  use Misc::Stopwatch;
  };
  $@ and do { $result = $@; chomp $result };
  return $@ ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t2 - True
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 11
# ------------------------------------------------------------------------------

sub t2 {
  my $result = eval {
  my $sw = Misc::Stopwatch->new();
  };
  $@ and die $@;
  return $result ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t3 - Does not abort
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 25
# ------------------------------------------------------------------------------

sub t3 {
  no warnings 'closure';  # allows one test case to setup subroutines for 
                          # subsequent tests.
  my $result = eval {
  my $sw = Misc::Stopwatch->new()->start();
  };
  $@ and do { $result = $@; chomp $result };
  return $@ ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t4 - Does not abort
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 41
# ------------------------------------------------------------------------------

sub t4 {
  no warnings 'closure';  # allows one test case to setup subroutines for 
                          # subsequent tests.
  my $result = eval {
  my $sw = Misc::Stopwatch->new()->start()->lap();
  };
  $@ and do { $result = $@; chomp $result };
  return $@ ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t5 - Does not abort
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 54
# ------------------------------------------------------------------------------

sub t5 {
  no warnings 'closure';  # allows one test case to setup subroutines for 
                          # subsequent tests.
  my $result = eval {
  my $sw = Misc::Stopwatch->new()->start()->stop();
  };
  $@ and do { $result = $@; chomp $result };
  return $@ ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t6 - True
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 76
# ------------------------------------------------------------------------------

sub t6 {
  my $result = eval {
  Misc::Stopwatch->new()->start()->elapsed();
  };
  $@ and die $@;
  return $result ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t7 - Does not abort
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 97
# ------------------------------------------------------------------------------

sub t7 {
  no warnings 'closure';  # allows one test case to setup subroutines for 
                          # subsequent tests.
  my $result = eval {
  my $sw = Misc::Stopwatch->new()->reset();
  };
  $@ and do { $result = $@; chomp $result };
  return $@ ? 1 : 0;
}
# ------------------------------------------------------------------------------
# t8 - False
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 111
# ------------------------------------------------------------------------------

sub t8 {
  my $result = eval {
  Misc::Stopwatch->new()->is_running();
  };
  $@ and die $@;
  return $result ? 0 : 1;
}
# ------------------------------------------------------------------------------
# t9 - True
# Generated from /var/src/build/out/perl-Apache2-LogUtil-00.01001/lib/Misc/Stopwatch.pm line: 112
# ------------------------------------------------------------------------------

sub t9 {
  my $result = eval {
  Misc::Stopwatch->new()->start()->is_running();
  };
  $@ and die $@;
  return $result ? 1 : 0;
}
