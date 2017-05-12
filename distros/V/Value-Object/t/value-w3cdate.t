#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use strict;
use warnings;

use Value::Object::W3CDate;

my @invalid_dates = (
    [ '',           'Empty string' ],
    [ '07-27-2015', 'Wrong order' ],
    [ '2015-7-27',  'One digit month' ],
    [ '2015-07-7',  'One digit day' ],
    [ '2015-13-27', 'Month out of range' ],
    [ '2015-07-32', 'Day out of range for any month' ],
    [ '2015-06-31', 'Day out of range for 30-day month' ],
    [ '2015-02-29', 'Day out of range for February' ],
    [ '2012-02-30', 'Day out of range for Leap February' ],
    [ '2015/07/27', 'Wrong date separator' ],
);

plan tests => 3 + @invalid_dates;

throws_ok { Value::Object::W3CDate->new() } qr/\AValue::Object::W3CDate/, 'Undefined value';

foreach my $test ( @invalid_dates )
{
    throws_ok { Value::Object::W3CDate->new( $test->[0] ) } qr/\AValue::Object::W3CDate/, "Bad date: $test->[1]";
}

my $date = Value::Object::W3CDate->new( '2015-07-27' );
isa_ok( $date, 'Value::Object::W3CDate', '$date' );
is( $date->value, '2015-07-27', 'Correct value' );
