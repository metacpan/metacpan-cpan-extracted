use strict;
use warnings;

use Test::More;
my $tests = 7;
plan tests => $tests;

my $class = 'Form::Processor::Field::Hour';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( 0 );
$field->validate_field;
ok( !$field->has_error, '0 in range' );

$field->input( 23 );
$field->validate_field;
ok( !$field->has_error, '23 in range' );

$field->input( 12 );
$field->validate_field;
ok( !$field->has_error, '12 in range' );

$field->input( -1  );
$field->validate_field;
ok( $field->has_error, '-1 out of range' );


$field->input( 24 );
$field->validate_field;
ok( $field->has_error, '24 out of range' );

