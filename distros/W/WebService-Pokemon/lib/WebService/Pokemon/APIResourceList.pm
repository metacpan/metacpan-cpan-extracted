package WebService::Pokemon::APIResourceList;

use utf8;
use strictures 2;
use namespace::clean;

use Moo;
use Types::Standard qw(Any ArrayRef HashRef InstanceOf Int Str);
use Test::More;

our $VERSION = '0.10';

has api => (
    isa => InstanceOf['WebService::Pokemon'],
    is => 'rw',
);

has response => (
    isa => HashRef,
    is  => 'rw',
);

has count => (
    isa => Int,
    is  => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->response->{count};
    },
);

has previous => (
    isa => Any,
    is  => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->response->{previous};
    },
);

has next => (
    isa => Any,
    is  => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->response->{next};
    },
);

has results => (
    isa => ArrayRef,
    is  => 'rw',
    lazy => 1,
    builder => 1,
);

sub _build_results {
    my ($self) = @_;

    return $self->response->{results} if (!$self->api->autoload);

    my $urls = [map { $_->{url} } @{$self->response->{results}}];

    my $results = [];
    foreach my $url (@{$urls}) {
        push @{$results}, $self->api->resource_by_url($url);
    }

    return $results;
}

1;
