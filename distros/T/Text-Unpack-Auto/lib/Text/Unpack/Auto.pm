use strict;
use warnings;
package Text::Unpack::Auto;

# ABSTRACT: automatically generates unpack strings

use parent 'Exporter';  # inherit all of Exporter's methods
use List::Util qw(reduce pairmap max min);

our @EXPORT = qw(guess_unpack auto_unpack);
our @EXPORT_OK = qw();  # symbols to export on reques

sub rle_encode { shift =~ s/(.)\1*/$1 . ":" . length($&) . " "/grse }

sub rle_decode { shift =~ s/(\d+):(.) /$2 x $1/grse }

sub rle_to_unpack { join '', pairmap { ($a ? 'a' : 'x') . $b } (map { split ":", $_  } split ' ', shift) }

sub close_gaps {
    my ($str, $n) = @_;
    return $str unless $n > 1;
    my $min_gap = $n - 1;
    $str =~ s/
		 (?<=1)          # preceded by a data column (lookbehind)
		 (               # capture the gap
		     0{1,$min_gap}   # whitespace columns, up to $min_gap wide
		 )               # gaps wider than this are real column separators
		 (?=1)           # followed by a data column (lookahead)
	     /1 x length($1)/gex;
    return $str;
}

sub guess_unpack {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};

    my @zeros = map { my $z = s/\S/1/gr; $z =~ s/\s/0/g; $z } @_;

    my $result = reduce { $a | $b } @zeros;
    $result = close_gaps($result, $opts->{minimum_gap}) if ($opts->{minimum_gap});
    my $unpack = rle_to_unpack(rle_encode($result));
    return $unpack;
}

sub auto_unpack {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};

    my @lines = @_;
    my $unpack = guess_unpack($opts, @lines);
    my $ml = max map { length($_) } @lines;

    return map { [ map { s/^\s+|\s+$//gr } unpack $unpack, sprintf "%-${ml}s",   $_ ] } @lines
}

1;

=head1 NAME

Text::Unpack::Auto - automatically generate unpack strings from fixed-width text

=head1 SYNOPSIS

    use Text::Unpack::Auto;

    my @rows = auto_unpack(@lines);
    for my $row (@rows) {
        say join ', ', @$row;
    }

    my $fmt = guess_unpack(@lines);

    my @rows = auto_unpack({ minimum_gap => 3 }, @lines);

=head1 DESCRIPTION

Detects fixed-width column boundaries in plain text and unpacks lines into
fields.

=head1 FUNCTIONS

L<Text::Unpack::Auto> exports L</"guess_unpack"> and L</"auto_unpack"> by
default.

=head2 guess_unpack

    my $fmt = guess_unpack(@lines);
    my $fmt = guess_unpack(\%opts, @lines);

Returns an L<unpack|perlfunc/unpack> template string derived from the column
boundaries detected in C<@lines>.

=head2 auto_unpack

    my @rows = auto_unpack(@lines);
    my @rows = auto_unpack(\%opts, @lines);

Unpacks each line into an arrayref of trimmed fields. Returns one arrayref per
input line.

=head2 Options

=over 2

=item minimum_gap

    minimum_gap => 3

Gaps narrower than this are treated as part of the surrounding column rather
than as column separators.

=back


=head1 AUTHOR

Simone Cesano

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Simone Cesano

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
