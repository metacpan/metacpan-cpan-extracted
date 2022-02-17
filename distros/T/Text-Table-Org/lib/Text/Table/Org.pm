package Text::Table::Org;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-23'; # DATE
our $DIST = 'Text-Table-Org'; # DIST
our $VERSION = '0.031'; # VERSION

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    # use that to get the field format and separators
    my $format = _get_format($widths);
    my $row_sep = _get_row_separator($widths);

    # here we go...
    my @table;

    push @table, "#+CAPTION: $params{caption}\n" if defined $params{caption};

    # if the first row's a header:
    my $data_begins = 0;
    if ( $params{header_row} ) {
        my $header_row = $rows->[0];
        $data_begins++;
        push @table, sprintf(
            $format,
            map { defined($header_row->[$_]) ? $header_row->[$_] : '' } (0..$max_index)
        );
        push @table, $row_sep;
    }

    # then the data
    my $i = 0;
    for my $i ($data_begins..$#$rows) {
        my $row = $rows->[$i];
        push @table, sprintf(
	    $format,
	    map { defined($row->[$_]) ? $row->[$_] : '' } (0..$max_index)
	);
        push @table, $row_sep if $params{separate_rows} && $i < $#$rows;
    }

    return join("", grep {$_} @table);
}

# FROM_MODULE: PERLANCAR::List::Util::PP
# BEGIN_BLOCK: max
sub max {
    return undef unless @_; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] > $res }
    $res;
}
# END_BLOCK: max

sub _get_cols_and_rows ($) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $rows = shift;
    return ( max( map { scalar @$_ } @$rows), scalar @$rows);
}

sub _maxwidths {
    my $rows = shift;
    # what's the longest array in this list of arrays?
    my $max_index = _max_array_index($rows);
    my $widths = [];
    for my $i (0..$max_index) {
        # go through the $i-th element of each array, find the longest
        my $max = max(map {defined $$_[$i] ? length($$_[$i]) : 0} @$rows);
        push @$widths, $max;
    }
    return $widths;
}

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return max( map { $#$_ } @$rows );
}

sub _get_format {
    my $widths = shift;
    return "| ".join(" | ",map { "%-${_}s" } @$widths)." |\n";
}

sub _get_row_separator {
    my $widths = shift;
    return "|-".join("-+-",map { "-" x $_ } @$widths)."-|\n";
}

1;
# ABSTRACT: Generate Org tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Org - Generate Org tables

=head1 VERSION

This document describes version 0.031 of Text::Table::Org (from Perl distribution Text-Table-Org), released on 2022-01-23.

=head1 SYNOPSIS

 use Text::Table::Org;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::Org::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as an Org text table.

The example shown in the SYNOPSIS generates the following table:

 | Name  | Rank     | Serial   |
 |-------+----------+----------|
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=item * header_row (bool)

If given a true value, the first row in the data will be interpreted as a header
row, and separated from the rest of the table with a ruled line.

=item * separate_rows (bool)

If set to true, will add separator line between data rows.

=item * caption

Optional. String. If set, will add this line to the beginning of output (C<table
caption> will be the actual caption string that you provide):

 #+CAPTION: table caption

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Org>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Org>.

=head1 SEE ALSO

This module is currently basically L<Text::Table::Tiny> 0.03 modified to output
Org tables instead of its original variant table format.

The output of this module is very similar to that of L<Text::MarkdownTable>. In
fact, Org recognizes its output as a valid Org table (the only difference is
that corner marker is C<|> instead of the Org standard of C<+>).

Some other text table modules: L<Text::ANSITable>, L<Text::ASCIITable>,
L<Text::FormatTable>, L<Text::Table>, L<Text::TabularDisplay>.

See also L<Bencher::Scenario::TextTableModules>.

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

This software is copyright (c) 2022, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Org>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
