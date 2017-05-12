use strict;
use warnings;

use Test::More;
my $tests = 4;
plan tests => $tests;

my $class = 'Form::Processor::Field::Username';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );

my $field = $class->new(
    name    => 'test_field',
    type    => $name,
);

ok( defined $field,  'new() called' );

$field->input( 'myusername' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );

$field->input( 'f oo' );
$field->validate_field;
ok( $field->has_error, 'has spaces' );

