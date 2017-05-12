#!/usr/bin/perl -w
use strict;

# ------------------------------------------------------------------------------
# THIS IS A GENERATED SCRIPT, CHANGES MADE HERE WILL BE OVERWRITTEN
# ------------------------------------------------------------------------------

use lib qw(../lib);

use Perl::Module;
use Data::Hub::Util qw(:all);
use Data::Hub qw($Hub);

our ($tidx,$test,$tinfo,$result,$total_tests) = (0,undef,undef,'',0);
$$Hub{'/sys/OPTS/v'} = 0 unless defined $$Hub{'/sys/OPTS/v'};
main();

# ------------------------------------------------------------------------------
# main - Test harness
# ------------------------------------------------------------------------------

sub main {
  $test = 1; # start at 1 to match ExtUtils::Command::MM
  my ($pass_count,$fail_count) = (0,0);
  while (eval("defined &t$test")) {
    $tinfo = $$Hub{"harness.hf/testcases/$tidx"};
    die "Cannot find testcase: $tidx\n" unless defined $tinfo;
    $result = '';
    $total_tests++;
    my $passed = eval( "&t$test()" );
    if( $@ ) {
      $result = $@;
      $passed = 0;
    } else {
      $passed = !$passed if( $$tinfo{'invert'} );
    }
    if( $passed ) {
      $pass_count++;
      $result ||= '';
      printstatus( "passed: $result" ) if $$Hub{'/sys/OPTS/v'} > 1;
      printstatus( 'passed' ) if $$Hub{'/sys/OPTS/v'} eq 1;
    } else {
      $fail_count++;
      $result = 'undef' unless defined $result;
      chomp $result;
      my $prefix = $result =~ /\n/ ? "FAILED:\n" : "FAILED: ";
      printstatus( "$prefix$result" );
    }
    $test++;
    $tidx++;
  }
  print "$pass_count of $total_tests passed.\n";
  exit ($pass_count == $total_tests ? 0 : 1);
}

# ------------------------------------------------------------------------------
# printstatus - Print pass/fail message
# ------------------------------------------------------------------------------

sub printstatus {
  printf "Test [%4d] %-25s line %5d: %s\n",
    $test,
    path_name($$tinfo{'package'}),
    $$tinfo{'lineno'}, @_;
}

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
