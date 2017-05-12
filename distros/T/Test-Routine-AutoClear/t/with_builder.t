use Test::Routine::AutoClear;
use Test::Routine::Util;
use Test::More;

has built => (
    is        => 'ro',
    autoclear => 1,
    required  => 1,
    clearer   => '_clear_built',
);

has doubly_built => (
    is => 'ro',
    autoclear => 1,
);

test "Can build a builder" => sub {
    my ($self) = @_;

    isa_ok($self->doubly_built, 'Test::Routine::Meta::Builder');
};

my $was_built;

test "Resetting calls the builder" => sub {
    my $self = shift;

    ok $was_built;
    $was_built = '';
    push @{$self->built}, 'built';
    $self->_clear_built;
    is_deeply $self->built, [];
    ok $was_built;
};

run_me "Pass a builder", {
    built => builder(sub { $was_built++; [] }),
    doubly_built => builder { builder { [] } },
};
done_testing;
