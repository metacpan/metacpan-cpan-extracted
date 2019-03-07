package Test::WWW::Stub::Intercepter;

use strict;
use warnings;
use List::MoreUtils ();

use Test::WWW::Stub::Handler;

sub new {
    my ($class) = @_;
    return bless { registry => {} }, $class;
}

sub intercept {
    my ($self, $uri, $env, $req) = @_;
    for my $pattern (sort { length $a <=> length $b } keys %{ $self->{registry} }) {
        for my $handler (@{$self->{registry}->{$pattern}}) {
            my $maybe_res = $handler->try_call($uri, $env, $req);
            return $maybe_res if $maybe_res;
        }
    }
    return undef;
}

sub register {
    my ($self, $uri_or_re, $app_or_res) = @_;
    my $handler = Test::WWW::Stub::Handler->factory($uri_or_re, $app_or_res);
    $self->{registry}->{$uri_or_re} //= [];
    unshift @{$self->{registry}->{$uri_or_re}}, $handler;
    return $handler;
}

sub unregister {
    my ($self, $uri_or_re, $handler) = @_;
    return unless exists $self->{registry}->{$uri_or_re};

    my $idx = List::MoreUtils::firstidx { $_ eq $handler } @{$self->{registry}->{$uri_or_re}};
    splice @{$self->{registry}->{$uri_or_re}}, $idx, 1;
}

1;
