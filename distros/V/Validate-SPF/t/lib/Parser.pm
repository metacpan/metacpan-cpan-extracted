package t::lib::Parser;

# ABSTRACT: parser testing utils

use strict;
use warnings;
use YAML qw( LoadFile );
use File::Spec;

my %prefix = (
    version     => '',
    a           => 'mech-',
    all         => 'mech-',
    ip4         => 'mech-',
    ip6         => 'mech-',
    mx          => 'mech-',
    ptr         => 'mech-',
    include     => 'mech-',
    exists      => 'mech-',
    unknown     => 'mod-',
    redirect    => 'mod-',
    exp         => 'mod-',
);

my %_cache;

sub positive_for {
    my ( undef, $thing, $extra ) = @_;

    my $cases = read_cases( $thing );

    if ( keys %{ $cases->{positive} } && has_extra( $extra ) ) {
        my @items = keys %{ $cases->{positive} };

        @{ $cases->{positive} }{ @items } =
            map { +{ %{ $cases->{positive}->{$_} }, %$extra } }
                @items;
    }

    return %{ $cases->{positive} };
}

sub negative_for {
    my ( undef, $thing, $extra ) = @_;

    my $cases = read_cases( $thing );

    if ( keys %{ $cases->{negative} } && has_extra( $extra ) ) {
        my @items = keys %{ $cases->{negative} };

        @{ $cases->{negative} }{ @items } =
            map { +{ %{ $cases->{negative}->{$_} }, %$extra } }
                @items;
    }

    return %{ $cases->{negative} };
}

sub read_cases {
    my ( $thing ) = @_;

    my $filename = File::Spec->catfile( qw( t lib data ), ( $prefix{ $thing } || '' ). $thing . '.yaml' );

    return  $_cache{ $filename }    if exists $_cache{ $filename };

    my $cases;

    eval {
        $_cache{ $filename } = LoadFile( $filename );
        1;
    } or do {
        warn 'unable to load: ' . $filename . ': ' . $@;

        $_cache{ $filename } = {
            positive => {},
            negative => {},
        };
    };

    return $_cache{ $filename };
}

sub has_extra {
    my ( $extra ) = @_;

    return defined $extra && ref $extra eq 'HASH' && keys %$extra;
}

1;
