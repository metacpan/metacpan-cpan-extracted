use strict;
use warnings;

use Test::More;
my $tests = 13;
plan tests => $tests;

my $class = 'Form::Processor::Field::WeekdayStr';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
    multiple => 1,
);

ok( defined $field,  'new() called' );

for ( 0 .. 6 ) {
    $field->input( $_ );
    $field->validate_field;
    ok( !$field->has_error, $_ . ' is valid' );
}

$field->input( -1 );
$field->validate_field;
ok( $field->has_error, '-1 is not valid day of the week' );

$field->input( 7 );
$field->validate_field;
ok( $field->has_error, '7 is not valid day of the week' );


$field->input( [ 1, 3, 5 ] );
$field->validate_field;
ok( !$field->has_error, '1 3 5 is valid days of the week' );

$field->input( [ 1, 3, 7 ] );
$field->validate_field;
ok( $field->has_error, '1 3 7 included invalid 7' );
