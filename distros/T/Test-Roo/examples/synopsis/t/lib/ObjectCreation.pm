package ObjectCreation;
use Test::Roo::Role;    # loads Moo::Role and Test::More

requires 'class';       # we need this fixture

test 'object creation' => sub {
    my $self = shift;
    require_ok( $self->class );
    my $obj  = new_ok( $self->class );
};

1;
