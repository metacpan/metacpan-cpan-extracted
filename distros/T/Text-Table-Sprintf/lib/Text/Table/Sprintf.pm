# we strive for minimality
## no critic: TestingAndDebugging::RequireUseStrict
package Text::Table::Sprintf;

#IFUNBUILT
# # use strict 'subs', 'vars';
# # use warnings;
#END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-07'; # DATE
our $DIST = 'Text-Table-Sprintf'; # DIST
our $VERSION = '0.006'; # VERSION

our %FEATURES = (
    set_v => {
        TextTable => 1,
    },

    features => {
        TextTable => {
            can_align_cell_containing_wide_character => 0,
            can_align_cell_containing_color_code     => 0,
            can_align_cell_containing_newline        => 0,
            can_use_box_character                    => 0,
            can_customize_border                     => 0,
            can_halign                               => 0,
            can_halign_individual_row                => 0,
            can_halign_individual_column             => 0,
            can_halign_individual_cell               => 0,
            can_valign                               => 0,
            can_valign_individual_row                => 0,
            can_valign_individual_column             => 0,
            can_valign_individual_cell               => 0,
            can_rowspan                              => 0,
            can_colspan                              => 0,
            can_color                                => 0,
            can_color_theme                          => 0,
            can_set_cell_height                      => 0,
            can_set_cell_height_of_individual_row    => 0,
            can_set_cell_width                       => 0,
            can_set_cell_width_of_individual_column  => 0,
            speed                                    => 'fast',
            can_hpad                                 => 0,
            can_hpad_individual_row                  => 0,
            can_hpad_individual_column               => 0,
            can_hpad_individual_cell                 => 0,
            can_vpad                                 => 0,
            can_vpad_individual_row                  => 0,
            can_vpad_individual_column               => 0,
            can_vpad_individual_cell                 => 0,
        },
    },
);

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";
    # XXX check that all rows contain the same number of columns

    return "" unless @$rows;

    # determine the width of each column
    my @widths;
    for my $row (@$rows) {
        for (0..$#{$row}) {
            my $len = length $row->[$_];
            $widths[$_] = $len if !defined $widths[$_] || $widths[$_] < $len;
        }
    }

    # determine the sprintf format for a single row
    my $rowfmt = join(
        "",
        (map { ($_ ? "" : "|") . " %-$widths[$_]s |" } 0..$#widths),
        "\n");
    my $line = join(
        "",
        (map { ($_ ? "" : "+") . ("-" x ($widths[$_]+2)) . "+" } 0..$#widths),
        "\n");

    # determine the sprintf format for the whole table
    my $tblfmt;
    if ($params{header_row}) {
        $tblfmt = join(
            "",
            $line,
            $rowfmt,
            $line,
            (map { $rowfmt . ($params{separate_rows} && $_ < $#{$rows} ? $line : '') } 1..@$rows-1),
            $line,
        );
    } else {
        $tblfmt = join(
            "",
            $line,
            (map { $rowfmt . ($params{separate_rows} && $_ < $#{$rows} ? $line : '') } 1..@$rows),
            $line,
        );
    }

    # generate table
    sprintf $tblfmt, map { @$_ } @$rows;
}

*generate_table = \&table;

1;
# ABSTRACT: Generate simple text tables from 2D arrays using sprintf()

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Sprintf - Generate simple text tables from 2D arrays using sprintf()

=head1 VERSION

This document describes version 0.006 of Text::Table::Sprintf (from Perl distribution Text-Table-Sprintf), released on 2022-01-07.

=head1 SYNOPSIS

 use Text::Table::Sprintf;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::Sprintf::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as a simple text table.

The example shown in the SYNOPSIS generates the following table:

 +-------+----------+----------+
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |
 +-------+----------+----------+

This module models its interface on L<Text::Table::Tiny> 0.03, employs the same
technique of using C<sprintf()>, but takes the technique further by using a
single large format and C<sprintf> the whole table. This results in even more
performance gain (see benchmark result or benchmark using
L<Acme::CPANModules::TextTable>).

Caveats: make sure each row contains the same number of elements. Otherwise, the
table will not be correctly formatted (cells might move to another row/column).

=for Pod::Coverage ^(max)$

=head1 DECLARED FEATURES

Features declared by this module:

=head2 From feature set TextTable

Features from feature set L<TextTable|Module::Features::TextTable> declared by this module:

=over

=item * can_align_cell_containing_color_code

Value: no.

=item * can_align_cell_containing_newline

Value: no.

=item * can_align_cell_containing_wide_character

Value: no.

=item * can_color

Can produce colored table.

Value: no.

=item * can_color_theme

Allow choosing colors from a named set of palettes.

Value: no.

=item * can_colspan

Value: no.

=item * can_customize_border

Let user customize border character in some way, e.g. selecting from several available borders, disable border.

Value: no.

=item * can_halign

Provide a way for user to specify horizontal alignment (leftE<sol>middleE<sol>right) of cells.

Value: no.

=item * can_halign_individual_cell

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual cells.

Value: no.

=item * can_halign_individual_column

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual columns.

Value: no.

=item * can_halign_individual_row

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual rows.

Value: no.

=item * can_hpad

Provide a way for user to specify horizontal padding of cells.

Value: no.

=item * can_hpad_individual_cell

Provide a way for user to specify different horizontal padding of individual cells.

Value: no.

=item * can_hpad_individual_column

Provide a way for user to specify different horizontal padding of individual columns.

Value: no.

=item * can_hpad_individual_row

Provide a way for user to specify different horizontal padding of individual rows.

Value: no.

=item * can_rowspan

Value: no.

=item * can_set_cell_height

Allow setting height of rows.

Value: no.

=item * can_set_cell_height_of_individual_row

Allow setting height of individual rows.

Value: no.

=item * can_set_cell_width

Allow setting height of rows.

Value: no.

=item * can_set_cell_width_of_individual_column

Allow setting height of individual rows.

Value: no.

=item * can_use_box_character

Can use terminal box-drawing character when drawing border.

Value: no.

=item * can_valign

Provide a way for user to specify vertical alignment (topE<sol>middleE<sol>bottom) of cells.

Value: no.

=item * can_valign_individual_cell

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual cells.

Value: no.

=item * can_valign_individual_column

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual columns.

Value: no.

=item * can_valign_individual_row

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual rows.

Value: no.

=item * can_vpad

Provide a way for user to specify vertical padding of cells.

Value: no.

=item * can_vpad_individual_cell

Provide a way for user to specify different vertical padding of individual cells.

Value: no.

=item * can_vpad_individual_column

Provide a way for user to specify different vertical padding of individual columns.

Value: no.

=item * can_vpad_individual_row

Provide a way for user to specify different vertical padding of individual rows.

Value: no.

=item * speed

Subjective speed rating, relative to other text table modules.

Value: "fast".

=back

For more details on module features, see L<Module::Features>.

=head1 FUNCTIONS

=head2 table

Usage:

 my $table_str = Text::Table::Sprintf::table(%params);

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=item * header_row (bool)

If given a true value, the first row in the data will be interpreted as a header
row, and separated from the rest of the table with a ruled line.

=item * separate_row (bool)

If set to true, will draw separator line between data rows.

=back

=head2 generate_table

Alias for L</table>, for compatibility with L<Text::Table::Tiny>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Sprintf>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Sprintf>.

=head1 SEE ALSO

L<Text::Table::Tiny>

Other text table modules listed in L<Acme::CPANModules::TextTable>. The selling
point of Text::Table::Sprintf is performance and light footprint (just about a
page of code that does not use I<any> module, core or otherwise).

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

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Sprintf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
