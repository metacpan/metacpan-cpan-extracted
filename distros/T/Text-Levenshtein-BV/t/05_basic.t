#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(
../lib/
./lib/
);

use Test::More;
use Test::More::UTF8;

my $class = 'Text::Levenshtein::BV';

use_ok($class);

my $object = new_ok($class);

if (1) {
    ok( $object = Text::Levenshtein::BV::new($class), 'Text::Levenshtein::BV::new($class)' );
    ok( $object = $class->new(), '$class->new()' );
    is( scalar keys %$object, 0, 'is scalar keys %$object, 0' );

    ok( $object = $class->new(1,2), '$class->new(1,2)' );
    is( $object->{1}, 2,            'is $object->{1}, 2' );

    ok( $object = $class->new({}), '$class->new({})');
    is( scalar keys %$object, 0,   'is scalar keys %$object, 0');

    ok( $object = $class->new({a => 1}), '$class->new({a => 1})' );
    is( $object->{a}, 1,                 'is $object->{a}, 1' );

    ok( $object = $class->new( a => 1, b => 2 ), '$class->new( a => 1, b => 2 )' );
    is( $object->{a}, 1, 'is $object->{a}, 1' );
    is( $object->{b}, 2, 'is $object->{b}, 2' );

}

done_testing;
