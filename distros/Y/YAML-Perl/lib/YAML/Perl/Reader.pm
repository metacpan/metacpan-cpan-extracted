package YAML::Perl::Reader;
use strict;
use warnings;

our $VERSION = '0.12';

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub read {
    my ($self) = @_;
    return $self->{input};
}

1;
