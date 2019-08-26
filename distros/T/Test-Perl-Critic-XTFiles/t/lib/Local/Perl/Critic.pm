package Local::Perl::Critic;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Local::Perl::Critic::Config;

use Class::Tiny 1 {
    config => sub { Local::Perl::Critic::Config->new; },
};

sub violation {
    my ( $self, $file, $violation ) = @_;

    if ( !exists $self->{_files}{$file} ) {
        $self->{_files}{$file} = [];
    }

    if ( defined $violation ) {
        push @{ $self->{_files}{$file} }, $violation;
    }

    return;
}

sub critique {
    my ( $self, $file ) = @_;

    die "File not found: $file\n" if !exists $self->{_files}{$file};

    return @{ $self->{_files}{$file} };
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
