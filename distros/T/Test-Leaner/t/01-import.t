#!perl -T

use strict;
use warnings;

use Test::More ();

BEGIN {
 delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE};
 *tm_is = \&Test::More::is;
}

Test::More::plan(tests => 2 * 15);

require Test::Leaner;

my @syms = qw<
 plan
 skip
 done_testing
 pass
 fail
 ok
 is
 isnt
 like
 unlike
 cmp_ok
 is_deeply
 diag
 note
 BAIL_OUT
>;

unless ($Test::More::VERSION > 0.51) {
 delete $main::{$_} for @syms;
}

for (@syms) {
 eval { Test::Leaner->import(import => [ $_ ]) };
 tm_is $@, '', "import $_";
 my $proto = ($_ eq 'unlike' and $Test::More::VERSION < 0.4802)
             ? '$$;$'
             : prototype("Test::More::$_");
 tm_is prototype($_), $proto, "prototype $_";
}
