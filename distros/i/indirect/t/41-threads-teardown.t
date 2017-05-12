#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'indirect' => 'indirect::I_THREADSAFE()' ],
 'run_perl',
);

use Test::Leaner tests => 3;

SKIP: {
 skip 'Fails on 5.8.2 and lower' => 1 if "$]" <= 5.008_002;

 my $status = run_perl <<' RUN';
  my ($code, @expected);
  BEGIN {
   $code = 2;
   @expected = qw<X Z>;
  }
  sub cb { --$code if $_[0] eq shift(@expected) || q{DUMMY} }
  use threads;
  $code = threads->create(sub {
   eval q{return; no indirect hook => \&cb; new X;};
   return $code;
  })->join;
  eval q{new Y;};
  eval q{return; no indirect hook => \&cb; new Z;};
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0,
        'loading the pragma in a thread and using it outside doesn\'t segfault';
}

SKIP: {
 my $status = run_perl <<' RUN';
  use threads;
  BEGIN { require indirect; }
  sub X2::DESTROY { eval 'no indirect; 1'; exit 1 if $@ }
  threads->create(sub {
   my $x = bless { }, 'X2';
   $x->{self} = $x;
   return;
  })->join;
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'indirect can be loaded in eval STRING during global destruction at the end of a thread';
}

SKIP: {
 my $status = run_perl <<' RUN';
  use threads;
  use threads::shared;
  my $code : shared;
  $code = 0;
  no indirect hook => sub { lock $code; ++$code };
  sub X3::DESTROY { eval $_[0]->{code} }
  threads->create(sub {
   my $x = bless { code => 'new Z3' }, 'X3';
   $x->{self} = $x;
   return;
  })->join;
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 my $code = $status >> 8;
 is $code, 1, 'indirect checks eval STRING during global destruction at the end of a cloned thread';
}
