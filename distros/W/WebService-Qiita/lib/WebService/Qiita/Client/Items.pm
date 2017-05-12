package WebService::Qiita::Client::Items;
use strict;
use warnings;
use utf8;

use parent qw(WebService::Qiita::Client::Base);

sub post_item {
    my ($self, $params) = @_;
    $self->post('/items', $params);
}

sub update_item {
    my ($self, $uuid, $params) = @_;
    $self->put("/items/$uuid", $params);
}

sub delete_item {
    my ($self, $uuid) = @_;
    $self->delete("/items/$uuid");
}

sub item {
    my ($self, $uuid) = @_;
    $self->get("/items/$uuid");
}

sub search_items {
    my ($self, $query, $params) = @_;
    $params ||= {};
    $params->{q} = $query;
    $self->get("/search", $params);
}

sub stock_item {
    my ($self, $uuid) = @_;
    $self->put("/items/$uuid/stock");
}

sub unstock_item {
    my ($self, $uuid) = @_;
    $self->delete("/items/$uuid/unstock");
}

1;
__END__
