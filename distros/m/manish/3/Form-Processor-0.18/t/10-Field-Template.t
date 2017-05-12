package Form::Processor::Field::Template;
use strict;
use warnings;
use lib './t';
use MyTest
    tests   => 5,
    recommended => [qw/ Template::Parser /];




my $class = 'Form::Processor::Field::Template';
my $name = $1 if $class =~ /::([^:]+)$/;

# Mosty to test for bad nesting

my $good_template = <<'';
    This is a template [% foo %]
    <p>This is nice
    and clean
    </p>
    <p><b>and bold</b></p>

my $bad_template = <<'';
    [% foo;  bar baz %]
    <p>This is nice
    and clean but not well formatted
    </p>
    <p><b>and bold without ending tag</p>



    use_ok( $class );
    my $field = $class->new(
        name    => 'test_field',
        type    => $name,
        form    => undef,
    );

    ok( defined $field,  'new() called' );

    $field->input( $good_template );
    $field->validate_field;
    ok( !$field->has_error, 'Test for errors 1' );


    $field->input(  $bad_template );
    $field->validate_field;
    ok( $field->has_error, 'Test for failure 2' );
    like( $field->errors->[0], qr/unexpected token \(baz\)/, 'Check parser message' );


