use strict;
use warnings;

use Test::More;
my $tests = 6;
plan tests => $tests;

my $class = 'Form::Processor::Field::USZipcode';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( 94610 );
$field->validate_field;
ok( !$field->has_error, '5 digits' );

$field->input( '95610-1234' );
$field->validate_field;
ok( !$field->has_error, 'zip+4' );

$field->input( '95610-a234' );
$field->validate_field;
ok( $field->has_error, 'bad char' );

$field->input( 9124 );
$field->validate_field;
ok( $field->has_error, 'too short' );

