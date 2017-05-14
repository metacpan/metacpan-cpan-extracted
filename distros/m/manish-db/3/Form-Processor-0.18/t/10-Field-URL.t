use strict;
use warnings;

use Test::More;
my $tests = 4;
plan tests => $tests;

my $class = 'Form::Processor::Field::URL';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( 'http://www.perl.com/' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );

$field->input( 'foo.com' );
$field->validate_field;
ok( $field->has_error, 'Test for errors 2' );

