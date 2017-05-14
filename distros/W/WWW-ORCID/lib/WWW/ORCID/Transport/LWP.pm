package WWW::ORCID::Transport::LWP;

use strict;
use warnings;
use namespace::clean;
use Moo;
use LWP::UserAgent ();

with 'WWW::ORCID::Transport';

has _client => (
    is => 'ro',
    init_arg => 0,
    lazy => 1,
    builder => '_build_client',
);

sub _build_client {
    LWP::UserAgent->new;
}

sub get {
    my ($self, $url, $params, $headers) = @_;
    if ($params) {
        $url = $self->_param_url($url, $params);
    }
    my $res = $self->_client->get($url, %$headers);
    $res->code, $self->_get_headers($res), $res->content;
}

sub post_form {
    my ($self, $url, $form, $headers) = @_;
    my $res = $self->_client->post($url, $form, %$headers);
    $res->code, $self->_get_headers($res), $res->content;
}

sub post {
    my ($self, $url, $body, $headers) = @_;
    my $res = $self->_client->post($url, %$headers, Content => $body);
    $res->code, $self->_get_headers($res), $res->content;
}

sub _get_headers {
    my ($self, $msg) = @_;
    my $headers = {};
    for my $key ($msg->header_field_names) {
        $headers->{lc $key} = $msg->header($key);
    }
    $headers;
}

1;
