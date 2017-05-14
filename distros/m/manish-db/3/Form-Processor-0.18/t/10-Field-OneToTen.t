use strict;
use warnings;

use Test::More;
my $tests = 25;
plan tests => $tests;

# silly thing
my $class = 'Form::Processor::Field::OneToTen';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
    required=> 1,
);

ok( defined $field,  'new() called' );

for ( 1 .. 10 ) {
    $field->input( $_ );
    $field->validate_field;
    ok( !$field->has_error, 'Test for errors ' . $_ );
    is( $field->value, $_, 'Test true == ' . $_ );
}

$field->input( 11 );
$field->validate_field;
ok( $field->has_error, 'Test for errors 11' );
$field->input( undef );
$field->validate_field;
ok( $field->has_error, 'Test for errors undef' );
$field->input( 'abc');
$field->validate_field;
ok( $field->has_error, 'Test for errors abc' );



