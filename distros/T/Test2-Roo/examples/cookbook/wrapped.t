use strict;
use Test2::Roo;

has fixture => (
    is => 'rw',
    lazy => 1,
    builder => 1,
    clearer => 1,
);

sub _build_fixture { "Hello World" }

sub fresh_test {
    my ($name, $code) = @_;
    test $name, sub {
        my $self = shift;
        $self->clear_fixture;
        $code->($self);
    };
}

fresh_test 'first' => sub {
    my $self = shift;
    is ( $self->fixture, 'Hello World', "fixture has default" );
    $self->fixture("Goodbye World");
};

fresh_test 'second' => sub {
    my $self = shift;
    is ( $self->fixture, 'Hello World', "fixture has default" );
};

run_me;
done_testing;
