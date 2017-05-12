package WebService::Qiita::Client::Users;
use strict;
use warnings;
use utf8;

use parent qw(WebService::Qiita::Client::Base);

sub user_items {
    my ($self, $url_name, $params) = @_;

    my $path = defined $url_name ? "/users/$url_name/items" : '/items';
    $self->get($path, $params);
}

sub user_following_tags {
    my ($self, $url_name, $params) = @_;
    $self->get("/users/$url_name/following_tags", $params);
}

sub user_following_users {
    my ($self, $url_name, $params) = @_;
    $self->get("/users/$url_name/following_users", $params);
}

sub user_stocks {
    my ($self, $url_name, $params) = @_;

    my $path = defined $url_name ? "/users/$url_name/stocks" : '/stocks';
    $self->get($path, $params);
}

sub user {
    my ($self, $url_name) = @_;

    my $path = defined $url_name ? "/users/$url_name" : '/user';
    $self->get($path);
}

1;
