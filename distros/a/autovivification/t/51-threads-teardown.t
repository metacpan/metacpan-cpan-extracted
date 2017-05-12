#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'autovivification' => 'autovivification::A_THREADSAFE()' ],
 'run_perl',
);

use Test::Leaner tests => 2;

SKIP:
{
 skip 'Fails on 5.8.2 and lower' => 1 if "$]" <= 5.008_002;

 my $status = run_perl <<' RUN';
  my $code = 1 + 2 + 4;
  use threads;
  $code -= threads->create(sub {
   eval q{no autovivification; my $x; my $y = $x->{foo}; $x};
   return defined($x) ? 0 : 1;
  })->join;
  $code -= defined(eval q{my $x; my $y = $x->{foo}; $x}) ? 2 : 0;
  $code -= defined(eval q{no autovivification; my $x; my $y = $x->{foo}; $x})
           ? 0 : 4;
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0,
        'loading the pragma in a thread and using it outside doesn\'t segfault';
}

SKIP: {
 my $status = run_perl <<' RUN';
  use threads;
  BEGIN { require autovivification; }
  sub X::DESTROY {
   eval 'no autovivification; my $x; my $y = $x->{foo}{bar}; use autovivification; my $z = $x->{a}{b}{c};';
   exit 1 if $@;
  }
  threads->create(sub {
   my $x = bless { }, 'X';
   $x->{self} = $x;
   return;
  })->join;
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'autovivification can be loaded in eval STRING during global destruction at the end of a thread';
}
