package MyDist::X::BadArg;

use parent qw( MyDist::X::Base );

sub _new {
    my ($class, $name, $value) = @_;

    return $class->SUPER::_new( "Bad argument: “$name” ($value)", name => $name, value => $value );
}

1;
