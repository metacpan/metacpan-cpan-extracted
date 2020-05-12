package EachTest;
use Test2::Roo::Role;

has counter => (
    is      => 'rw',
    lazy    => 1,
    builder => 1,
);

requires '_build_counter';

before each_test => sub {
    my $self = shift;
    pass("starting before module modifier");
    $self->counter( $self->counter + 1 );
};

after each_test => sub {
    my $self = shift;
    $self->counter( $self->counter - 1 );
    pass("finishing after module modifier");
};

test 'positive' => sub { ok( shift->counter, "counter positive" ) };

1;
