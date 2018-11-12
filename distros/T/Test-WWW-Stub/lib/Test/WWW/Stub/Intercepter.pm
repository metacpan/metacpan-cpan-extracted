package Test::WWW::Stub::Intercepter;

use strict;
use warnings;

use Test::WWW::Stub::Handler;

sub new {
    my ($class) = @_;
    return bless { registry => {} }, $class;
}

sub intercept {
    my ($self, $uri, $env, $req) = @_;
    for my $pattern (sort { length $a <=> length $b } keys %{ $self->{registry} }) {
        my $handler = $self->{registry}->{$pattern};
        my $maybe_res = $handler->try_call($uri, $env, $req);
        return $maybe_res if $maybe_res;
    }
    return undef;
}

sub get_handler {
    my ($self, $uri_or_re) = @_;
    return $self->{registry}->{$uri_or_re};
}

sub register {
    my ($self, $uri_or_re, $app_or_res) = @_;
    my $handler = Test::WWW::Stub::Handler->factory($uri_or_re, $app_or_res);
    $self->{registry}->{$uri_or_re} = $handler;
}

sub unregister {
    my ($self, $uri_or_re) = @_;
    delete $self->{registry}->{$uri_or_re} if exists $self->{registry}->{$uri_or_re};
}

1;
