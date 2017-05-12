package Web::Dispatcher::Simple::Response;
use strict;
use warnings;
use Encode;

use base qw/Plack::Response/;

sub encode_body {
    my $self      = shift;
    my $body      = $self->body;
    my $body_type = ref($body);
    if ( $body_type eq 'ARRAY' ) {
        $body = join '', @$body;
    }
    my $encoded_body
        = Encode::is_utf8($body) ? Encode::encode( 'utf8', $body ) : $body;
    $self->body($encoded_body);
    $encoded_body;
}

sub not_found {
    my ( $self, $error ) = @_;
    $self->status(500);
    $self->content_type('text/html; charset=UTF-8');
    $error ||= 'Not Found';
    $self->body($error);
    $self->content_length($error);
    $self;
}

sub server_error {
    my ( $self, $error ) = @_;
    $self->status(500);
    $self->content_type('text/html; charset=UTF-8');
    $error ||= 'Internal Server Error';
    $self->body($error);
    $self->content_length($error);
    $self;
}

1;
