package Example;

use Test::Roo::Role;

use File::Basename qw/ basename /;

has data_file => (
    is      => 'ro',
    default => sub { $0 },
);

has regex => (
    is      => 'ro',
    default => sub { qr/data/ },
);

has epoch => (
    is      => 'lazy',
    default => sub { time },
);

test 'filename matches regex' => sub {
    my ($self) = @_;

    like basename( $self->data_file ), $self->regex;
};

test 'epoch' => sub {
    my ($self) = @_;

    ok $self->epoch < time(), 'evaluated time';
};

1;
