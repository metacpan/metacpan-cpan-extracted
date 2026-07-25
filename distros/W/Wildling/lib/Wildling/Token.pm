package Wildling::Token;

use strict;
use warnings;

sub new {
    my ( $class, $options ) = @_;
    $options ||= {};

    my $src          = exists $options->{src} ? $options->{src} : '';
    my $start_length = _default_integer( $options->{startLength}, 1 );
    my $end_length   = _default_integer( $options->{endLength},   1 );
    my $variants     = $options->{variants} || [];

    my $count = 0;
    my $n     = scalar @$variants;
    for my $length ( $start_length .. $end_length ) {
        $count += $n**$length;
    }

    return bless {
        src          => $src,
        start_length => $start_length,
        end_length   => $end_length,
        variants     => $variants,
        count        => $count,
    }, $class;
}

sub count {
    my ($self) = @_;
    return $self->{count};
}

sub src {
    my ($self) = @_;
    return $self->{src};
}

sub get {
    my ( $self, $index ) = @_;
    return '' if $index > $self->{count} - 1 || $index < 0;
    return '' if $index == 0 && $self->{start_length} == 0;

    my $index_with_offset = $index;
    my $string_length     = $self->{start_length};
    my $n                 = scalar @{ $self->{variants} };

    for my $length ( $self->{start_length} .. $self->{end_length} ) {
        $string_length = $length;
        my $offset_count = $n**$length;
        last if $index_with_offset < $offset_count;
        $index_with_offset -= $offset_count;
    }

    my @string_array;
    for ( 1 .. $string_length ) {
        my $variant_index = $index_with_offset % $n;
        $index_with_offset = int( $index_with_offset / $n );
        push @string_array, $self->{variants}[$variant_index];
    }
    return join '', @string_array;
}

sub _default_integer {
    my ( $option, $fallback ) = @_;
    return $fallback unless defined $option && !ref($option);
    return $fallback unless $option =~ /\A(?:0|[1-9][0-9]*)\z/;
    my $n = 0 + $option;
    return $n >= 0 ? $n : $fallback;
}

1;
