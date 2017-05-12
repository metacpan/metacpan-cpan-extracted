package ClassConstructor;
use Test::Roo::Role;

requires 'class';

test 'object creation' => sub {
    my $self = shift;
    require_ok( $self->class );
    my $obj = new_ok( $self->class );
};

1;
