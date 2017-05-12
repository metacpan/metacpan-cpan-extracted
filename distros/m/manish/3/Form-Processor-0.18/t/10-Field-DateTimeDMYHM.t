use strict;
use warnings;

use lib './t';
use MyTest
    tests   => 2,
    recommended => [qw/ DateTime /];



    my $class = 'Form::Processor::Field::DateTimeDMYHM';

    my $name = $1 if $class =~ /::([^:]+)$/;

    use_ok( $class );

    my $field = $class->new(
        name    => 'test_field',
        type    => $name,
        form    => undef,
    );

    ok( defined $field,  'new() called' );


