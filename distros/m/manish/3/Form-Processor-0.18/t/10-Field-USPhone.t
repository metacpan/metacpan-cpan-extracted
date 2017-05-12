use strict;
use warnings;

use Test::More;
my $tests = 5;
plan tests => $tests;

# not too useful -- considering extensions
my $class = 'Form::Processor::Field::USPhone';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( '555 555-1212' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );

$field->input( '5555551212' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );


$field->input( '(555) 555-1212' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );





