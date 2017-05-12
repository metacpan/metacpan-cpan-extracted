package Text::Ligature;

use 5.006;
use strict;
use warnings;
use utf8;
use parent 'Exporter';
use Carp;

our $VERSION     = '0.02';
our @EXPORT_OK   = qw< to_ligatures from_ligatures to_ligature from_ligature >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# TODO: remove to_ligature/from_ligature in next release
*to_ligature   = \&to_ligatures;
*from_ligature = \&from_ligatures;

my @defaults = qw< ff fi fl ffi ffl >;

my %lig_for = (
    ff  => 'ﬀ',
    fi  => 'ﬁ',
    fl  => 'ﬂ',
    ffi => 'ﬃ',
    ffl => 'ﬄ',
    ft  => 'ﬅ',
    st  => 'ﬆ',
);

my %chars_for = reverse %lig_for;

sub to_ligatures {
    my ($text) = @_;

    if (@_ != 1) {
        carp 'to_ligatures() expects one argument';
        return;
    }

    # longest token matching
    for my $chars (sort { length $b <=> length $a } @defaults) {
        $text =~ s/$chars/$lig_for{$chars}/g;
    }

    return $text;
}

sub from_ligatures {
    my ($text) = @_;

    if (@_ != 1) {
        carp 'from_ligatures() expects one argument';
        return;
    }

    for my $lig (keys %chars_for) {
        $text =~ s/$lig/$chars_for{$lig}/g;
    }

    return $text;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Ligature - Replace sequences of characters with typographic ligatures

=head1 VERSION

This document describes Text::Ligature version 0.02.

=head1 SYNOPSIS

    use Text::Ligature qw( :all );

    to_ligatures('offloading floral offices refines effectiveness');
    # returns: oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness

    from_ligatures('oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness');
    # returns: offloading floral offices refines effectiveness

=head1 DESCRIPTION

Replaces sequences of characters with corresponding typographic ligatures.

    Characters  Ligature
    ff          ﬀ
    fi          ﬁ
    fl          ﬂ
    ffi         ﬃ
    ffl         ﬄ

=begin comment

TODO: Support additional specified characters.

Additional:

    Characters  Ligature
    ft          ﬅ
    st          ﬆ

=end comment

This is an early release.  Specifying the ligatures to replace will be
supported in a future version.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
