package WebService::Qiita::Client::Tags;
use strict;
use warnings;
use utf8;

use parent qw(WebService::Qiita::Client::Base);

sub tag_items {
    my ($self, $url_name, $params) = @_;
    $self->get("/tags/$url_name/items", $params);
}

sub tags {
    my ($self, $params) = @_;
    $self->get("/tags", $params);
}


1;
