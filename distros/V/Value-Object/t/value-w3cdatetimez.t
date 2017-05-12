#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use strict;
use warnings;

use Value::Object::W3CDateTimeZ;

my @invalid_dates = (
    [ '',                          'Empty string' ],
    [ '2015-07-27',                'Missing time' ],
    [ '2015-07-27T',               'Missing time 2' ],
    [ '07-27-2015T12:00:00Z',      'Wrong date order' ],
    [ '2015-7-27T12:00:00Z',       'One digit month' ],
    [ '2015-07-7T12:00:00Z',       'One digit day' ],
    [ '2015-13-27T12:00:00Z',      'Month out of range' ],
    [ '2015-07-32T12:00:00Z',      'Day out of range for any month' ],
    [ '2015-06-31T12:00:00Z',      'Day out of range for 30-day month' ],
    [ '2015-02-29T12:00:00Z',      'Day out of range for February' ],
    [ '2012-02-30T12:00:00Z',      'Day out of range for Leap February' ],
    [ '2015-07-27t12:00:00Z',      'Wrong time separator' ],
    [ '2015-07-27 12:00:00Z',      'Wrong time separator space' ],
    [ '2015-07-27T12:00:00',       'Missing timezone marker' ],
    [ '2015-07-27T12:00:00z',      'Wrong case timezone marker' ],
    [ '2015-07-27T2:00:00Z',       'One digit hour' ],
    [ '2015-07-27T12:0:00Z',       'One digit minute' ],
    [ '2015-07-27T12:00:0Z',       'One digit second' ],
    [ '2015-07-27T12:00Z',         'Missing seconds' ],
    [ '2015-07-27T12:00:00+05:00', 'Explicit time offset' ],
    [ '2015-07-27T12:00:00-05:00', 'Explicit Negative time offset' ],
);

plan tests => 3 + @invalid_dates;

throws_ok { Value::Object::W3CDateTimeZ->new() } qr/\AValue::Object::W3CDateTimeZ/, 'Undefined value';

foreach my $test ( @invalid_dates )
{
    throws_ok { Value::Object::W3CDateTimeZ->new( $test->[0] ) } qr/\AValue::Object::W3CDateTimeZ/,
        "Bad date: $test->[1]";
}

my $date = Value::Object::W3CDateTimeZ->new( '2015-07-27T20:26:00Z' );
isa_ok( $date, 'Value::Object::W3CDateTimeZ', '$date' );
is( $date->value, '2015-07-27T20:26:00Z', 'Correct value' );
