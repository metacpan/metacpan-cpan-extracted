#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

sub skipall {
 my ($msg) = @_;
 require Test::Leaner;
 Test::Leaner::plan(skip_all => $msg);
}

use Config qw/%Config/;

BEGIN {
 my $force = $ENV{PERL_TEST_LEANER_TEST_THREADS} ? 1 : !1;
 my $t_v   = $force ? '0' : '1.67';
 skipall 'This perl wasn\'t built to support threads'
                                                    unless $Config{useithreads};
 skipall 'perl 5.13.4 required to test thread safety'
                                             unless $force or "$]" >= 5.013_004;
 skipall "threads $t_v required to test thread safety"
                                              unless eval "use threads $t_v; 1";
}

use Test::Leaner; # after threads

BEGIN {
 skipall 'This Test::Leaner isn\'t thread safe' unless Test::Leaner::THREADSAFE;
 plan tests => 8 * 10;
 defined and diag "Using threads $_" for $threads::VERSION;
}

sub tick {
 sleep 1 if rand() < 0.5;
}

sub worker {
 my $tid = threads->tid;
 diag "spawned thread $tid";
 tick;
 for (1 .. 10) {
  cmp_ok 1, '==', '1.0', "test $_ in thread $tid";
  tick;
 }
}

$_->join for map threads->create(\&worker), 1 .. 8;
