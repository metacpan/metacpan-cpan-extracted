use strict;
use warnings;

use Test::More;
my $tests = 7;
plan tests => $tests;

my $class = 'Form::Processor::Field::IntRange';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
    range_start => 30,
    range_end   => 39,
);

ok( defined $field,  'new() called' );

$field->input( 30 );
$field->validate_field;
ok( !$field->has_error, '30 in range' );

$field->input( 39 );
$field->validate_field;
ok( !$field->has_error, '39 in range' );

$field->input( 35 );
$field->validate_field;
ok( !$field->has_error, '35 in range' );

$field->input( 29 );
$field->validate_field;
ok( $field->has_error, '29 out of range' );


$field->input( 40 );
$field->validate_field;
ok( $field->has_error, '40 out of range' );

