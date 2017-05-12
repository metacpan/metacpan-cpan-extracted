#! /usr/bin/perl
use strict;
use warnings;
use Perlude;
use Test::More;

eval { fold pairs "haha" };
ok $@, "die when arg isn't ref";

for
(   [ "each pairs from hash"
    , 5
    , {qw<
        a_key a_value
        b_key b_value
        c_key c_value
        d_key d_value
        e_key e_value
    >} ]

# WHEN ARRAYs implemented
#
# ,   [ "each pairs from alphabet"
#     , 5
#     , ['a'..'e'] ]
# 
# ,   [ "each pairs from weird cases"
#     , 4
#     , [ undef, 0, '', 'weird' ] ]
# 
# WHEN streams implemented
#
# ,   [ "each pairs from a stream"
#     , 5
#     , take 5, sub { state $x = 0; $x++ } ]

) {
    my ( $desc, $expected, $from ) = @$_;
    my $got = my @r = fold pairs $from;
    is $got, $expected, $desc;
}

done_testing;
