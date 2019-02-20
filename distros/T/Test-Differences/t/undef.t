#!perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Differences;

TODO: {
    local $TODO = "Should fail";
    eq_or_diff( undef, "", "undef eq ''" );
    eq_or_diff( undef, [], "undef eq []" );
    eq_or_diff( undef, 0, "undef eq 0" );
    eq_or_diff( "",    0, "'' eq 0" );
    eq_or_diff( [ 1, undef ], [ 1, "" ], "undef eq '' in array" );
    eq_or_diff( [ 1,   [ 2, undef ] ], [ 1,   [ 2, "" ] ],        "undef eq '' in deep array" );
    eq_or_diff( [ [1], [ 2, undef ] ], [ [1], [ 2, "" ] ],        "undef eq '' in AoAoS" );
    eq_or_diff( [ [1], [ 2, undef ] ], [ [1], [ 2, "<undef>" ] ], "undef eq <undef> in AoAoS" );
    eq_or_diff( [ 1, undef ], [ 1, ], "arrays of different length are equal" );
    eq_or_diff( { aa => undef }, { aa => '' },        "undef eq '' in hash" );
    eq_or_diff( { aa => undef }, { aa => '<undef>' }, "undef eq <undef> in hash" );
}

my $builder = Test::More->builder;
# The Test::Builder 1.5 way to do it
if ( $builder->can('history') ) {
    is $builder->history->pass_count - $builder->history->todo_count,
       $builder->history->literal_pass_count,
       "All TODO tests failed";
}
# The Test::Builder 0.x way to do it
else {
    eq_or_diff [ map { $_->{actual_ok} } $builder->details ], [ map { 0 } $builder->details ],
      "All TODO tests failed";
}
