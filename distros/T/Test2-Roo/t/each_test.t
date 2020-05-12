use Test2::Roo;

use lib 't/lib';

with 'EachTest';

sub _build_counter { return 0 }

before each_test => sub {
    my $self = shift;
    pass("starting before main modifier");
    $self->counter( $self->counter + 1 );
};

after each_test => sub {
    my $self = shift;
    $self->counter( $self->counter - 1 );
    pass("finishing after main modifier");
};

test 'is two' => sub { is( shift->counter, 2, "counter is 2" ) };

test 'still two' => sub { is( shift->counter, 2, "counter is still 2" ) };

run_me;
done_testing;
