package WebService::BuzzurlAPI::Request::UrlInfo;

use strict;
use base qw(WebService::BuzzurlAPI::Request::Base);

our $VERSION = 0.02;

sub filter_param {

    my($self, $param) = @_;
    $param->{url} = $self->drop_utf8flag($param->{url});
}

sub make_request_url {

    my($self, $param) = @_;
    my $path = sprintf $self->uri->path, "posts/get";
    $self->uri->path($path);
    $self->uri->query_form($param);
}


1;
