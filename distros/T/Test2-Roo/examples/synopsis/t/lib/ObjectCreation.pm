package ObjectCreation;
use Test2::Roo::Role;         # loads Moo::Role and Test2::V0
use Test2::Tools::LoadModule; # for require_ok

requires 'class';       # we need this fixture

test 'object creation' => sub {
    my $self = shift;
    require_ok( $self->class );
    my $obj;
    ok( lives { $obj = $self->class->new } )
      or diag $@;
    isa_ok( $obj, $self->class );
};

1;
