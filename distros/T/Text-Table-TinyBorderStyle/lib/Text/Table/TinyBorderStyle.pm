package Text::Table::TinyBorderStyle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'Text-Table-TinyBorderStyle'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.006;
use strict;
use warnings;

use List::Util ();

use Exporter qw(import);
our @EXPORT_OK = qw/ generate_table /;

sub generate_table {

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $border_style_name = $params{border_style} ||
        $ENV{TEXT_TABLE_TINY_BORDER_STYLE} ||
        $ENV{BORDER_STYLE} ||
        'BorderStyle::ASCII::SingleLine';

    require Module::Load::Util;
    my $border_style_obj = Module::Load::Util::instantiate_class_with_optional_args($border_style_name);

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    # use that to get the field format and separators
    my $row_format        = _get_row_format          ($border_style_obj, $widths);
    my $header_row_format = _get_header_row_format   ($border_style_obj, $widths);
    my $top_border        = _get_top_border          ($border_style_obj, $widths);
    my $head_row_sep      = _get_header_row_separator($border_style_obj, $widths);
    my $row_sep           = _get_row_separator       ($border_style_obj, $widths);
    my $bottom_border     = _get_bottom_border       ($border_style_obj, $widths);

    # here we go...
    my @table;
    push @table, $top_border;

    # if the first row's a header:
    my $data_begins = 0;
    if ( $params{header_row} ) {
        my $header_row = $rows->[0];
        $data_begins++;
        push @table, sprintf(
                         $header_row_format,
                         map { defined($header_row->[$_]) ? $header_row->[$_] : '' } (0..$max_index)
                     );
        push @table, $head_row_sep;
    }

    # then the data
    my $i = 0;
    foreach my $row ( @{ $rows }[$data_begins..$#$rows] ) {
        push @table, $row_sep if $params{separate_rows} && $i++;
        push @table, sprintf(
	    $row_format,
	    map { defined($row->[$_]) ? $row->[$_] : '' } (0..$max_index)
	);
    }

    # this will have already done the bottom if called explicitly
    push @table, $bottom_border;
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
        my $max = List::Util::max(map {defined $$_[$i] ? length($$_[$i]) : 0} @$rows);
        push @$widths, $max;
    }
    return $widths;
}

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return List::Util::max( map { $#$_ } @$rows );
}

# TODO: what if border character contains %
sub _get_row_format {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(3, 0). " ",
        join(" ".$border_style_obj->get_border_char(3, 1)." ",  map { "%-${_}s" } @$widths),
        " " . $border_style_obj->get_border_char(3, 2),
    );
}

# TODO: what if border character contains %
sub _get_header_row_format {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(1, 0) . " ",
        join(" ".$border_style_obj->get_border_char(1, 1)." ",  map { "%-${_}s" } @$widths),
        " " . $border_style_obj->get_border_char(1, 2),
    );
}

sub _get_top_border {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(0, 0) . $border_style_obj->get_border_char(0, 1),
        join($border_style_obj->get_border_char(0, 1) . $border_style_obj->get_border_char(0, 2) . $border_style_obj->get_border_char(0, 1),  map { $border_style_obj->get_border_char(0, 1, $_) } @$widths),
        $border_style_obj->get_border_char(0, 1) . $border_style_obj->get_border_char(0, 3),
    );
}

sub _get_header_row_separator {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(2, 0) . $border_style_obj->get_border_char(2, 1),
        join($border_style_obj->get_border_char(2, 1) . $border_style_obj->get_border_char(2, 2) . $border_style_obj->get_border_char(2, 1),  map { $border_style_obj->get_border_char(2, 1, $_) } @$widths),
        $border_style_obj->get_border_char(2, 1) . $border_style_obj->get_border_char(2, 3),
    );
}

sub _get_row_separator {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(4, 0) . $border_style_obj->get_border_char(4, 1),
        join($border_style_obj->get_border_char(4, 1) . $border_style_obj->get_border_char(4, 2) . $border_style_obj->get_border_char(4, 1),  map { $border_style_obj->get_border_char(4, 1, $_) } @$widths),
        $border_style_obj->get_border_char(4, 1) . $border_style_obj->get_border_char(4, 3),
    );
}

sub _get_bottom_border {
    my ($border_style_obj, $widths) = @_;
    join(
        "",
        $border_style_obj->get_border_char(5, 0) . $border_style_obj->get_border_char(5, 1) ,
        join($border_style_obj->get_border_char(5, 1) . $border_style_obj->get_border_char(5, 2) . $border_style_obj->get_border_char(5, 1),  map { $border_style_obj->get_border_char(5, 1, $_) } @$widths),
        $border_style_obj->get_border_char(5, 1) . $border_style_obj->get_border_char(5, 3),
    );
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

Text::Table::TinyBorderStyle - Text::Table::Tiny + support for colored text

=head1 VERSION

This document describes version 0.003 of Text::Table::TinyBorderStyle (from Perl distribution Text-Table-TinyBorderStyle), released on 2020-06-11.

=head1 SYNOPSIS

 use Text::Table::TinyBorderStyle qw/ generate_table /;

 my $rows = [
     # header row
     ['Name','Rank','Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print generate_table(rows => $rows, header_row => 1, border_style => 'BorderStyle::ASCII::SingleLine');

=head1 DESCRIPTION

This module is like L<Text::Table::Tiny> (0.04) with added support for using
border styles. For more details about border styles, see L<BorderStyle>
specification. The styles are in C<BorderStyle::*> modules. Try installing and
using the border style modules to see what they look like.

Interface, options, and format variables are the same as in Text::Table::Tiny.

=for Pod::Coverage ^(.+)$

=head1 ENVIRONMENT

=head2 BORDER_STYLE

Set default for C<border_style> argument. See also
L</TEXT_TABLE_TINY_BORDER_STYLE>.

=head2 BORDER_STYLE

Set default for C<border_style> argument. Takes precedence over
L</BORDER_STYLE>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-TinyBorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-TinyBorderStyle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-TinyBorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny> and other variants like L<Text::Table::TinyColor>,
L<Text::Table::TinyWide>, L<Text::Table::TinyColorWide>.

L<BorderStyle> and C<BorderStyle::*> modules, e.g.
L<BorderStyle::ASCII::SingleLine> or L<BorderStyle::UTF8::DoubleLine>.

L<Text::Table::Any>

L<Text::ANSITable> which also supports border styles as well as color themes,
aligning wide/colored text, and other features, but with larger footprint and
slower rendering speed.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
