use Test2::Roo;

has counter => ( is => 'rw', default => sub { 0 } );

sub is_positive {
    my $self = shift;
    ok( $self->counter > 0, "counter is positive" );
}

before is_positive => sub { shift->counter( 1 ) };

test 'hookable' => sub { shift->is_positive };

run_me;
done_testing;
