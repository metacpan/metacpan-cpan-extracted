use 5.10.0;
use strict;
use warnings;

package Text::Bidi::Selection;
# ABSTRACT: Map visual selections to original logical text
$Text::Bidi::Selection::VERSION = '3.03';
use Carp qw(croak);


sub new {
    my $class = shift;
    croak 'Expected named arguments' if @_ % 2;
    my %args = @_;
    for my $name (keys %args) {
        croak "Unknown argument: $name"
            unless $name eq 'text' || $name eq 'visual_to_logical';
    }
    croak 'text must be a defined string' if !defined($args{text}) || ref($args{text});
    my $input = $args{visual_to_logical};
    my $entries = ref($input) ? eval { [@$input] } : undef;
    croak 'visual_to_logical must be an array reference' unless defined $entries;
    my $length = length($args{text});
    my @map;
    for my $entry (@$entries) {
        my @indices = !defined($entry) ? () : ref($entry) eq 'ARRAY' ? @$entry : ($entry);
        for my $index (@indices) {
            croak 'Map offsets must be non-negative integers within text'
                unless defined($index) && !ref($index) && $index =~ /\A[0-9]+\z/
                    && $index < $length;
        }
        push @map, [map { 0 + $_ } @indices];
    }
    return bless { text => $args{text}, map => \@map }, $class;
}


sub logical_ranges {
    my $self = shift;
    croak 'Expected visual start and end offsets' unless @_ == 2;
    my ($start, $end) = @_;
    for my $offset ($start, $end) {
        croak 'Visual offsets must be non-negative integers'
            unless defined($offset) && !ref($offset) && $offset =~ /\A[0-9]+\z/;
    }
    ($start, $end) = (0 + $start, 0 + $end);
    croak 'Visual range must satisfy 0 <= start <= end <= map length'
        if $start > $end || $end > @{$self->{map}};
    my %selected;
    for my $visual ($start..$end - 1) {
        $selected{$_} = 1 for @{$self->{map}[$visual]};
    }
    my @ranges;
    for my $logical (sort { $a <=> $b } keys %selected) {
        if (@ranges && $ranges[-1][1] == $logical) {
            ++$ranges[-1][1];
        } else {
            push @ranges, [$logical, $logical + 1];
        }
    }
    return \@ranges;
}


sub selected_text {
    my $self = shift;
    my $ranges = $self->logical_ranges(@_);
    return join '', map { substr($self->{text}, $_->[0], $_->[1] - $_->[0]) } @$ranges;
}


1;

__END__

=pod

=head1 NAME

Text::Bidi::Selection - Map visual selections to original logical text

=head1 VERSION

version 3.03

=head1 SYNOPSIS

    use Text::Bidi qw(log2vis);
    use Text::Bidi::Selection;

    my $logical = "abc \x{5d0}\x{5d1}\x{5d2}\x{5d3} xyz";
    my ($paragraph, $visual) = log2vis($logical);
    my $selection = Text::Bidi::Selection->new(
        text              => $logical,
        visual_to_logical => $paragraph->map,
    );

    my $ranges = $selection->logical_ranges(6, 10);
    # [[4, 6], [8, 10]]: two separate ranges in the original text
    my $text = $selection->selected_text(6, 10);
    # "\x{5d0}\x{5d1} x", without the unselected intervening letters

=head1 DESCRIPTION

This module translates a visual selection into ranges in the original
logical text, and extracts those ranges in logical reading order. A visual
selection can correspond to several separate logical ranges in mixed
bidirectional text. Unselected characters between those ranges are omitted.

The module takes a snapshot of its text and map. Later changes to the input
map, including a L<Text::Bidi::Paragraph/map> updated by another call to
C<visual>, do not affect an existing selection object.

Logical offsets count characters in the original Perl string, not UTF-8
bytes. Visual offsets count entries in the supplied map. For a paragraph map
these are character positions. A renderer may instead supply one entry per
terminal cell, grapheme, or glyph. It is responsible for translating mouse
coordinates into those visual offsets and defining word and line selection.

This module performs no rendering or shaping and has no dependency on
urxvt or the native FriBidi wrapper.

=head1 METHODS

=head2 new

    my $selection = Text::Bidi::Selection->new(
        text              => $logical,
        visual_to_logical => $map,
    );

C<text> is the original, unshaped logical string. C<visual_to_logical> is an
array reference (or an object that can be dereferenced as an array). Each
entry is one of:

=over

=item *

A non-negative character offset into C<text>.

=item *

An array reference of character offsets. For example, C<[2, 3]> can represent
a ligature containing two original characters, or a base character and its
combining mark.

=item *

C<undef> or C<[]> for a displayed position without a logical character,
such as padding or an inserted formatting mark.

=back

Several entries may refer to the same character, for example the cells of a
wide character. Selecting any of those entries selects that character once.
Offsets must be smaller than the length of C<text>. Invalid arguments croak.

=head2 logical_ranges

    my $ranges = $selection->logical_ranges($start, $end);

Return an array reference of C<[$start, $end]> logical ranges. All ranges
include their start and exclude their end. The input range uses visual
offsets and must satisfy C<0 E<lt>= $start E<lt>= $end E<lt>= map length>.
Invalid bounds croak; an empty selection returns C<[]>.

The returned ranges are sorted by logical offset, contain no duplicates,
and merge adjacent selected characters. Characters in a gap between ranges
are not selected. Each call returns new arrays that the caller may modify.

=head2 selected_text

    my $text = $selection->selected_text($start, $end);

Extract the ranges returned by L</logical_ranges> and concatenate them in
logical reading order. The result contains the original characters, without
shaping or mirroring. An empty or entirely unmapped selection returns C<''>.
Line breaks between separately rendered rows remain the caller's policy.

=head1 SEE ALSO

L<Text::Bidi>, L<Text::Bidi::Paragraph>

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
