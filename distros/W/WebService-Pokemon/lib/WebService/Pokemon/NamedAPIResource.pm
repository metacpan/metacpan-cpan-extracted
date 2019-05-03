package WebService::Pokemon::NamedAPIResource;

use utf8;
use strictures 2;
use namespace::clean;

use Moo;
use Types::Standard qw(HashRef InstanceOf);

our $VERSION = '0.11';

has api => (
    isa => InstanceOf['WebService::Pokemon'],
    is => 'rw',
);

has response => (
    isa => HashRef,
    is  => 'rw',
);

sub BUILD {
    my ($self, $args) = @_;

    foreach my $arg (keys %{$args}) {
        $self->$arg($args->{$arg}) if (defined $args->{$arg});
    }

    foreach my $arg (keys %{$self->response}) {
        $self->meta->add_attribute(
            $arg => (is => 'rw', lazy => 1, builder => 1)
        );

        my $value = $self->response->{$arg};

        if (ref $value eq 'HASH') {
            $value = WebService::Pokemon::NamedAPIResource->new(
                api => $self->api,
                response => $value
            );
        }

        if (ref $value eq 'ARRAY') {
            my $list;
            foreach my $v (@{$value}) {
                push @{$list},
                    WebService::Pokemon::NamedAPIResource->new(
                        api => $self->api,
                        response => $v
                    );
            }
            $value = $list;
        }

        $self->$arg($value);
    }

    return $self;
}

1;
