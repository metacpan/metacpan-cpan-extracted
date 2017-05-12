use strict;
use warnings;

use Test::More;
my $tests = 2;
plan tests => $tests;

my $class = 'Form::Processor::Field::Phone';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );
