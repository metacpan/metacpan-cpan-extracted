#!perl

use strict;
use warnings;

sub skipall {
 my ($msg) = @_;
 require Test::More;
 Test::More::plan(skip_all => $msg);
}

use Config qw<%Config>;

BEGIN {
 my $force = $ENV{PERL_RE_ENGINE_PLUGIN_TEST_THREADS} ? 1 : !1;
 my $t_v   = $force ? '0' : '1.67';
 my $ts_v  = $force ? '0' : '1.14';
 skipall 'This perl wasn\'t built to support threads'
                                                    unless $Config{useithreads};
 skipall 'perl 5.13.4 required to test thread safety'
                                             unless $force or "$]" >= 5.013_004;
 skipall "threads $t_v required to test thread safety"
                                              unless eval "use threads $t_v; 1";
 skipall "threads::shared $ts_v required to test thread safety"
                                     unless eval "use threads::shared $ts_v; 1";
}

use Test::More; # after threads

my $threads;
BEGIN { $threads = 10 }

BEGIN {
 require re::engine::Plugin;
 skipall 'This re::engine::Plugin isn\'t thread safe'
                                    unless re::engine::Plugin::REP_THREADSAFE();
 plan tests => 2 * 2 * $threads + 1;
 defined and diag "Using threads $_"         for $threads::VERSION;
 defined and diag "Using threads::shared $_" for $threads::shared::VERSION;
}

my $matches : shared = '';

use re::engine::Plugin comp => sub {
 my ($re) = @_;

 my $pat = $re->pattern;

 $re->callbacks(
  exec => sub {
   my ($re, $str) = @_;

   {
    lock $matches;
    $matches .= "$str==$pat\n";
   }

   return $str == $pat;
  },
 );
};

sub try {
 my $tid = threads->tid;

 my $rx = qr/$tid/;

 ok $tid =~ $rx, "'$tid' is matched in thread $tid";

 my $wrong = $tid + 1;
 ok $wrong !~ $rx, "'$wrong' is not matched in thread $tid";

 return;
}

no re::engine::Plugin;

my @tids = map threads->create(\&try), 1 .. $threads;

$_->join for @tids;

my %matches = map { $_ => 1 }
               grep length,
                split /\n/,
                 do { lock $matches; $matches };

is keys(%matches), 2 * $threads, 'regexps matched the correct number of times';

for my $i (1 .. $threads) {
 ok $matches{"$i==$i"}, "match '$i==$i' was correctly executed";
 my $j = $i + 1;
 ok $matches{"$j==$i"}, "match '$j==$i' was correctly executed";
}
