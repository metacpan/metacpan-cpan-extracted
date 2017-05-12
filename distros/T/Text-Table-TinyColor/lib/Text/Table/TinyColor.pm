package Text::Table::TinyColor;

our $DATE = '2016-10-19'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.006;
use strict;
use warnings;

use List::Util ();
use Text::ANSI::Util qw(ta_length ta_pad);

use Exporter qw(import);
our @EXPORT_OK = qw/ generate_table /;

our $COLUMN_SEPARATOR = '|';
our $ROW_SEPARATOR = '-';
our $CORNER_MARKER = '+';
our $HEADER_ROW_SEPARATOR = '=';
our $HEADER_CORNER_MARKER = 'O';

sub generate_table {

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    # use that to get the field format and separators
    my $format = _get_format($widths);
    my $row_sep = _get_row_separator($widths);
    my $head_row_sep = _get_header_row_separator($widths);

    # here we go...
    my @table;
    push @table, $row_sep;

    # if the first row's a header:
    my $data_begins = 0;
    if ( $params{header_row} ) {
        my $header_row = $rows->[0];
        $data_begins++;
        push @table, sprintf(
                         $format,
                         map { ta_pad((defined($header_row->[$_]) ? $header_row->[$_] : ''), $widths->[$_]) } (0..$max_index)
                     );
        push @table, $params{separate_rows} ? $head_row_sep : $row_sep;
    }

    # then the data
    foreach my $row ( @{ $rows }[$data_begins..$#$rows] ) {
        push @table, sprintf(
	    $format,
	    map { ta_pad((defined($row->[$_]) ? $row->[$_] : ''), $widths->[$_]) } (0..$max_index)
	);
        push @table, $row_sep if $params{separate_rows};
    }

    # this will have already done the bottom if called explicitly
    push @table, $row_sep unless $params{separate_rows};
    return join("\n",grep {$_} @table);
}

sub _get_cols_and_rows ($) {
    my $rows = shift;
    return ( List::Util::max( map { scalar @$_ } @$rows), scalar @$rows);
}

sub _maxwidths {
    my $rows = shift;
    # what's the longest array in this list of arrays?
    my $max_index = _max_array_index($rows);
    my $widths = [];
    for my $i (0..$max_index) {
        # go through the $i-th element of each array, find the longest
        my $max = List::Util::max(map {defined $$_[$i] ? ta_length($$_[$i]) : 0} @$rows);
        push @$widths, $max;
    }
    return $widths;
}

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return List::Util::max( map { $#$_ } @$rows );
}

sub _get_format {
    my $widths = shift;
    return "$COLUMN_SEPARATOR ".join(" $COLUMN_SEPARATOR ",map { "%s" } @$widths)." $COLUMN_SEPARATOR";
}

sub _get_row_separator {
    my $widths = shift;
    return "$CORNER_MARKER$ROW_SEPARATOR".join("$ROW_SEPARATOR$CORNER_MARKER$ROW_SEPARATOR",map { $ROW_SEPARATOR x $_ } @$widths)."$ROW_SEPARATOR$CORNER_MARKER";
}

sub _get_header_row_separator {
    my $widths = shift;
    return "$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR".join("$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR",map { $HEADER_ROW_SEPARATOR x $_ } @$widths)."$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER";
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
{
    no warnings 'once';
    *table = \&generate_table;
}

1;
# ABSTRACT: Text::Table::Tiny + support for colored text

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::TinyColor - Text::Table::Tiny + support for colored text

=head1 VERSION

This document describes version 0.002 of Text::Table::TinyColor (from Perl distribution Text-Table-TinyColor), released on 2016-10-19.

=head1 SYNOPSIS

 use Term::ANSIColor;
 use Text::Table::TinyColor qw/ generate_table /;

 my $rows = [
     # header row
     [colored(['bright_green'],'Name'), colored(['bright_green'],'Rank'), colored(['bright_green'],'Serial')],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', colored(['bold'], '8745')],
 ];
 print generate_table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module is like L<Text::Table::Tiny> (0.04) with added support for colored
text (text that contains ANSI color codes). With this module, the colored text
will still line up.

Interface, options, and format variables are the same as in Text::Table::Tiny.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-TinyColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-TinyColor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-TinyColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

L<Text::Table::TinyWide> for table with wide character support.

L<Text::Table::TinyColorWide> for table with colored text and wide character
support.

L<Text::Table::Any>

L<Text::ANSITable> for more formatting options and wide character support, but
with larger footprint and slower rendering speed.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
