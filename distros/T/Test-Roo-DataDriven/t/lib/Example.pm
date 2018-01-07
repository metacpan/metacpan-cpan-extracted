package Example;

use feature qw/ state /;

use Test::Roo::Role;

use Class::Inspector;
use File::Basename qw/ basename /;

has data_file => (
    is      => 'ro',
    default => sub { $0 },
);

has index => (
    is       => 'ro',
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

test 'sandbox' => sub {
    my ($self) = @_;

    state $counter = 0;

    state $package;

    note 'index = ' . ($self->index // 'undef');

    unless ( $self->index && $self->index > 1 ) {
        $package = "Test::Roo::DataDriven::Sandbox" . $counter++;
    }

    ok !Class::Inspector->loaded($package), "$package namespace clean";

};

1;
