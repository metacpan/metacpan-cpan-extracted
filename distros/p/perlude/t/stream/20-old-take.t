#! /usr/bin/perl
use strict;
use warnings;
use Perlude;
use Test::More tests => 12;

my ( @input, $got, $expected );
# 
# @input    = qw/ test toto tata tutu et le reste /;
# $got      = [fold takeWhile { /^t/ } sub { shift @input }];
# $expected = [qw/ test toto tata tutu /];
# 
# is_deeply( $got, $expected, "takeWhile works");

# sub begins_with_t ($) { takeWhile { /^t/ } shift }
# my @t = qw/ toto tata aha /;
# print "$_\n" for fold begins_with_t sub { shift @t }

my $fold_ok = is
( fold( sub { () } )
, 0 
, "fold works" );

unless ( $fold_ok ) {
    diag("fold failed so every other tests will fail too");
    exit;
}

sub test_it {
    my ( $f, $input, $expected, $desc ) = @_;
    my $got = [fold $f->( unfold @$input ) ];
    is_deeply( $got, $expected, $desc );
}

for my $test (

    [ sub { takeWhile { /^t/ } shift }
    , [qw/ toto tata haha got /]
    , [qw/ toto tata /]
    , "takeWhile ok"
    ],

    [ sub { take 2, shift }
    , [qw/ foo bar pan bing /]
    , [qw/ foo bar /]
    , "take ok"
    ],

    [ sub { filter { /a/ } shift }
    , [qw/ foo bar pan bing /]
    , [qw/ bar pan /]
    , "filter ok"
    ],

) { test_it @$test }


@input = qw/ foo bar test /;
sub eat { fold take shift, sub { @input ? (shift @input) : () } };

{
    my $take_test = 1;
    for my $takes
    ( [ [qw/ foo bar /] , [eat 2]  ]
    , [ [qw/ test /]    , [eat 10] ]
    , [ []              , [eat 10] ]
    ) { my ( $expected, $got ) = @$takes;
        is_deeply ( $got, $expected , "take test $take_test ok" );
        $take_test++;
    }
}

SKIP: {
    skip "mapC not (yet?) reimplmented", 1;

    sub take2ones { take 2, sub { 1 } }

    $got = [ fold mapC { $_ + 1 } take2ones ];
    $expected = [ 2, 2 ];
    is_deeply( $got, $expected, 'mapC works');
}

SKIP: {
    skip "mapR not (yet?) reimplmented", 2;

    my $count = 0;
    $got = mapR { $count+=$_ } take2ones;
    is( $got  , undef, 'mapR returns nothing');
    is( $count,     2, 'mapR did things');
}

($got) = fold drop 2, do {
    my @a = qw/ a b c d e f /;
    sub { @a ? (shift @a) : () }
};
is( $got, 'c', 'drop works' );

($got) = fold drop 2, do {
    my @a = qw/ /;
    sub { @a ? (shift @a) : () }
};
is( $got, undef, 'drop works again' );


# take 3, cycle 1, 2;
