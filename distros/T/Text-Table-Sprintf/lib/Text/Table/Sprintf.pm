package Text::Table::Sprintf;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-10'; # DATE
our $DIST = 'Text-Table-Sprintf'; # DIST
our $VERSION = '0.001'; # VERSION

#IFUNBUILT
# # use strict;
# # use warnings;
#END IFUNBUILT

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
            (map { $rowfmt } 1..@$rows-1),
            $line,
        );
    } else {
        $tblfmt = join(
            "",
            $line,
            (map { $rowfmt } 1..@$rows),
            $line,
        );
    }

    # generate table
    sprintf $tblfmt, map { @$_ } @$rows;
}

1;
# ABSTRACT: Generate simple text tables from 2D arrays using sprintf()

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Sprintf - Generate simple text tables from 2D arrays using sprintf()

=head1 VERSION

This document describes version 0.001 of Text::Table::Sprintf (from Perl distribution Text-Table-Sprintf), released on 2020-08-10.

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

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Sprintf>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Sprintf>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Sprintf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

Other text table modules listed in L<Acme::CPANModules::TextTable>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
