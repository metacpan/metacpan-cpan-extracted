package Text::Table::TinyBorderStyle;

use 5.006;
use strict;
use warnings;

use List::Util ();

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'Text-Table-TinyBorderStyle'; # DIST
our $VERSION = '0.005'; # VERSION

our @EXPORT_OK = qw/ generate_table /;

sub generate_table {

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $border_style_name = $params{border_style} ||
        $ENV{TEXT_TABLE_TINY_BORDER_STYLE} ||
        $ENV{BORDER_STYLE} ||
        'BorderStyle::ASCII::SingleLine';

    require Module::Load::Util;
    my $border_style_obj = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefixes=>["BorderStyle", ""]}, $border_style_name);

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    my $table_has_header_row = $params{header_row} && @$rows;
    my $table_has_data_row   = @$rows >= ($params{header_row} ? 2:1);

    # use that to get the field format and separators
    my $row_format        = _get_row_format          ($border_style_obj, $widths);
    my $header_row_format = _get_header_row_format   ($border_style_obj, $widths);
    my $top_border        = _get_top_border          ($border_style_obj, $widths, $table_has_header_row, $table_has_data_row);
    my $head_row_sep      = _get_header_row_separator($border_style_obj, $widths);
    my $row_sep           = _get_row_separator       ($border_style_obj, $widths);
    my $bottom_border     = _get_bottom_border       ($border_style_obj, $widths, $table_has_header_row, $table_has_data_row);

    # here we go...
    my @table;
    push @table, $top_border;

    # if the first row's a header:
    my $data_begins = 0;
    {
        last unless $params{header_row};
        my $header_row = $rows->[0];
        last unless $header_row;
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

sub _get_cols_and_rows ($) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
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
    my ($border_style_obj, $widths, $table_has_header_row, $table_has_data_row) = @_;
    my %gbcargs = (for_data_row=>1);
    join(
        "",
        $border_style_obj->get_border_char(char=>'v_l', %gbcargs),
        " ",
        join(
            " ".
            $border_style_obj->get_border_char(char=>'v_i', %gbcargs).
            " ",
            map { "%-${_}s" } @$widths),
        " ",
        $border_style_obj->get_border_char(char=>'v_r', %gbcargs),
    );
}

# TODO: what if border character contains %
sub _get_header_row_format {
    my ($border_style_obj, $widths) = @_;
    my %gbcargs = (for_header_row=>1);
    join(
        "",
        $border_style_obj->get_border_char(char=>'v_l', %gbcargs),
        " ",
        join(
            " ".
            $border_style_obj->get_border_char(char=>'v_i', %gbcargs).
            " ",
            map { "%-${_}s" } @$widths),
        " ",
        $border_style_obj->get_border_char(char=>'v_r', %gbcargs),
    );
}

sub _get_top_border {
    my ($border_style_obj, $widths, $table_has_header_row, $table_has_data_row) = @_;
    my %gbcargs = ();
    if ($table_has_header_row) {
        $gbcargs{for_header_row} = 1;
    } else {
        $gbcargs{for_data_row} = 1;
    }

    # assume there's no top border when the rd_t character is empty
    my $rd_t = $border_style_obj->get_border_char(char=>'rd_t', %gbcargs);
    return '' unless length $rd_t;

    join(
        "",
        $rd_t,
        $border_style_obj->get_border_char(char=>'h_t', %gbcargs),
        join(
            $border_style_obj->get_border_char(char=>'h_t', %gbcargs).
            $border_style_obj->get_border_char(char=>'hd_t', %gbcargs).
            $border_style_obj->get_border_char(char=>'h_t', %gbcargs),
            map { sprintf("%-${_}s", $border_style_obj->get_border_char(char=>'h_t', repeat=>$_, %gbcargs)) } @$widths),
        $border_style_obj->get_border_char(char=>'h_t', %gbcargs),
        $border_style_obj->get_border_char(char=>'ld_t', %gbcargs),
    );
}

sub _get_header_row_separator {
    my ($border_style_obj, $widths) = @_;
    my %gbcargs = (for_header_data_separator=>1);
    join(
        "",
        $border_style_obj->get_border_char(char=>'rv_l', %gbcargs),
        $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
        join(
            $border_style_obj->get_border_char(char=>'h_i', %gbcargs).
            $border_style_obj->get_border_char(char=>'hv_i', %gbcargs).
            $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
            map { sprintf("%-${_}s", $border_style_obj->get_border_char(char=>'h_i', repeat=>$_, %gbcargs)) } @$widths),
        $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
        $border_style_obj->get_border_char(char=>'lv_r', %gbcargs),
    );
}

sub _get_row_separator {
    my ($border_style_obj, $widths) = @_;
    my %gbcargs = (for_data_row=>1, for_data_data_separator=>1);
    join(
        "",
        $border_style_obj->get_border_char(char=>'rv_l', %gbcargs),
        $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
        join(
            $border_style_obj->get_border_char(char=>'h_i', %gbcargs).
            $border_style_obj->get_border_char(char=>'hv_i', %gbcargs).
            $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
            map { sprintf("%-${_}s", $border_style_obj->get_border_char(char=>'h_i', repeat=>$_, %gbcargs)) } @$widths),
        $border_style_obj->get_border_char(char=>'h_i', %gbcargs),
        $border_style_obj->get_border_char(char=>'lv_r', %gbcargs),
    );
}

sub _get_bottom_border {
    my ($border_style_obj, $widths, $table_has_header_row, $table_has_data_row) = @_;
    my %gbcargs = ();
    if (!$table_has_data_row) {
        $gbcargs{for_header_row} = 1;
    } else {
        $gbcargs{for_data_row} = 1;
    }

    my $ru_b = $border_style_obj->get_border_char(char=>'ru_b', %gbcargs);
    # assume we don't have bottom border when ru_b character is empty
    return '' unless length $ru_b;

    join(
        "",
        $ru_b,
        $border_style_obj->get_border_char(char=>'h_b', %gbcargs),
        join(
            $border_style_obj->get_border_char(char=>'h_b', %gbcargs).
            $border_style_obj->get_border_char(char=>'hu_b', %gbcargs).
            $border_style_obj->get_border_char(char=>'h_b', %gbcargs),
            map { sprintf("%-${_}s", $border_style_obj->get_border_char(char=>'h_b', repeat=>$_, %gbcargs)) } @$widths),
        $border_style_obj->get_border_char(char=>'h_b', %gbcargs),
        $border_style_obj->get_border_char(char=>'lu_b', %gbcargs),
    );
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
{
    no warnings 'once';
    *table = \&generate_table;
}

1;
# ABSTRACT: Text::Table::Tiny + support for border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::TinyBorderStyle - Text::Table::Tiny + support for border styles

=head1 VERSION

This document describes version 0.005 of Text::Table::TinyBorderStyle (from Perl distribution Text-Table-TinyBorderStyle), released on 2022-02-14.

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

=head2 TEXT_TABLE_TINY_BORDER_STYLE

Set default for C<border_style> argument. Takes precedence over
L</BORDER_STYLE>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-TinyBorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-TinyBorderStyle>.

=head1 SEE ALSO

L<Text::Table::Tiny> and other variants like L<Text::Table::TinyColor>,
L<Text::Table::TinyWide>, L<Text::Table::TinyColorWide>.

L<BorderStyle> and C<BorderStyle::*> modules, e.g.
L<BorderStyle::ASCII::SingleLine> or L<BorderStyle::UTF8::DoubleLine>.

L<Text::Table::Any>

L<Text::ANSITable> which also supports border styles as well as color themes
(including coloring the borders), aligning wide/colored text, and other
features, but with larger footprint and slower rendering speed.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-TinyBorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
