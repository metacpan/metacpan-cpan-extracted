package Helm::Conf::Loader;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

sub load {
    my ($class, $uri) = @_;
    die "You must implement the load() method in your child class!";
}

__PACKAGE__->meta->make_immutable;

1;
