package Web::API::Mock::Resource;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.11";

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw/url header body status content_type/ ],
);

sub add {
    my ($self, $args) = @_;
    my $method = $args->{method} // 'GET';
    my $header = $args->{header} // {};
    my $body   = $args->{body} // '';
    my $status = $args->{status} // 200;
    my $content_type = $args->{content_type} // 'text/html';

    unless ( $self->body ) {
        $self->status({});
        $self->content_type({});
        $self->header({});
        $self->body({});
    }

    $self->status->{$method} = $status;
    $self->content_type->{$method} = $content_type;
    $self->header->{$method} = $header;
    $self->body->{$method} = $body;
}

sub response {
    my ($self, $method) = @_;
    $method //= 'GET';

    return {
        status       => $self->status->{$method},
        content_type => $self->content_type->{$method},
        header       => $self->header->{$method},
        body         => $self->body->{$method}
    }

}

sub status_404 {
    return {
        status       => 404,
        content_type => 'text/plain',
        method       => 'GET',
        header       => '',
        body         => '404 Not Found'
    }
}

sub status_501 {
    return {
        status       => 501,
        content_type => 'text/plain',
        method       => 'GET',
        header       => '',
        body         => '501 Not Implemented'
    }
}

1;
