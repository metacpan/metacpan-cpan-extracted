package Example;

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

my $Counter = 0;

my $Package;

test 'sandbox' => sub {
    my ($self) = @_;

    note 'index = ' . (defined $self->index ? $self->index : 'undef');

    unless ( $self->index && $self->index > 1 ) {
        $Package = "Test::Roo::DataDriven::Sandbox" . $Counter++;
    }

    ok !Class::Inspector->loaded($Package), "$Package namespace clean";

};

1;
