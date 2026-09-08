package Local::MockUA;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless { queue => [], requests => [] }, $class;
}

sub enqueue {
    my ($self, @responses) = @_;
    push @{ $self->{queue} }, @responses;
    return $self;
}

sub request {
    my ($self, $method, $url, $opts) = @_;
    push @{ $self->{requests} }, {
        method => $method,
        url    => $url,
        opts   => $opts,
    };

    die "MockUA request queue exhausted for $method $url\n"
      if !@{ $self->{queue} };

    my $response = shift @{ $self->{queue} };
    return ref($response) eq 'CODE'
      ? $response->($method, $url, $opts)
      : $response;
}

sub requests {
    my $self = shift;
    return $self->{requests};
}

sub last_request {
    my $self = shift;
    return $self->{requests}->[-1];
}

1;
