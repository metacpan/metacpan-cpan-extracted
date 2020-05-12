package ClassConstructor;
use Test2::Roo::Role;
use Test2::Tools::LoadModule qw( require_ok );
use Test2::V0 '!meta';

requires 'class';

test 'object creation' => sub {
    my $self = shift;
    require_ok( $self->class );
    my $obj;
    ok( lives { $obj = $self->class->new } )
      or diag $@;
    isa_ok( $obj, $self->class );
};

1;
