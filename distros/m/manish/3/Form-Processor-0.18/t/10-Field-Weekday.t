use strict;
use warnings;

use Test::More;
my $tests = 11;
plan tests => $tests;

my $class = 'Form::Processor::Field::Weekday';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
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


