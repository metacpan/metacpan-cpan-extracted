package WebService::BuzzurlAPI::Request::UserArticles;

use strict;
use base qw(WebService::BuzzurlAPI::Request::Base);

our $VERSION = 0.02;

sub filter_param {

    my($self, $param) = @_;
    $param->{userid} = $self->drop_utf8flag($param->{userid});
}


sub make_request_url {

    my($self, $param) = @_;
    my $path = sprintf $self->uri->path, "articles";
    $path .= "/" . $param->{userid};
    $self->uri->path($path);
}

1;
