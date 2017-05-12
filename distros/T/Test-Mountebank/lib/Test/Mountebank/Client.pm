package Test::Mountebank::Client;

use Moose;
our $VERSION = '0.001';
use Method::Signatures;
use HTTP::Tiny;
use JSON::Tiny qw(encode_json);
use Test::Mountebank::Imposter;

has ua => (
    is      => 'ro',
    default => sub { HTTP::Tiny->new() },
);
has base_url => ( is => 'ro', isa => 'Str', required => 1 );
has port => ( is => 'rw', isa => 'Int', default => 2525 );

method create_imposter(:$port = 4525, :$protocol = 'http') {
    return Test::Mountebank::Imposter->new(port => $port, protocol => $protocol);
}

method mb_url() {
    return $self->base_url . ":" . $self->port;
}

method is_available() {
    return $self->ua->head($self->mb_url)->{success};
}

method delete_imposters(@on_ports) {
    $self->ua->delete($self->mb_url . "/imposters/$_") for @on_ports;
}

method save_imposter(Test::Mountebank::Imposter $imp) {
    $self->ua->post(
        $self->mb_url . "/imposters",
        {
            headers => { "Content-Type" => "application/json" },
            content => $imp->as_json,
        },
    );
}

1;
