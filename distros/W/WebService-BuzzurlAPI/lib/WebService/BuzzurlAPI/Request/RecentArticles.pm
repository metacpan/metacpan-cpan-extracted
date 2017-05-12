package WebService::BuzzurlAPI::Request::RecentArticles;

use strict;
use base qw(WebService::BuzzurlAPI::Request::Base);

our($NUM, $OF, $THRESHOLD, $VERSION);

$NUM       = 5;
$OF        = 0;
$THRESHOLD = 0;
$VERSION   = 0.02;

sub filter_param {

    my($self, $param) = @_;
    $param->{num}       = $NUM if !$param->{num} || $param->{num} =~ /[^\d]/;
    $param->{of}        = $OF if !$param->{of} || $param->{of} =~ /[^\d]/;
    $param->{threshold} = $THRESHOLD if !$param->{threshold} || $param->{threshold} =~ /[^\d]/;
}


sub make_request_url {

    my($self, $param) = @_;
    my $path = sprintf $self->uri->path, "articles/recent";
    $self->uri->path($path);
    $self->uri->query_form($param);
    
}

1;
