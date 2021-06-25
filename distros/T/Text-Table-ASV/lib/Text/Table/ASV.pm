package Text::Table::ASV;

our $DATE = '2021-02-20'; # DATE
our $VERSION = '0.002'; # VERSION

#IFUNBUILT
# # use 5.010001;
# # use strict;
# # use warnings;
#END IFUNBUILT

sub _encode {
    my $val = shift;
    $val =~ s/[\x1c\x1d\x1e\x1f]/ /g;
    $val;
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $header_row = defined $params{header_row} ? $params{header_row} : 1;
    my $max_index = _max_array_index($rows);

    # here we go...
    my @table;

    # then the data
    my $i = 0;
    foreach my $row ( @{ $rows }[0..$#$rows] ) {
        $i++;
        next if $i==1 && !$header_row;
        push @table, join(
	    "\x1f",
	    map { _encode(defined($row->[$_]) ? $row->[$_] : '') } (0..$max_index)
	);
    }

    return join("\x1e", grep {$_} @table);
}

# FROM_MODULE: PERLANCAR::List::Util::PP
# BEGIN_BLOCK: max
sub max {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] > $res }
    $res;
}
# END_BLOCK: max

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return max( map { $#$_ } @$rows );
}

1;
# ABSTRACT: Generate ASV (ASCII separated value a.k.a. DEL a.ka. delimited ASCII)

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::ASV - Generate ASV (ASCII separated value a.k.a. DEL a.ka. delimited ASCII)

=head1 VERSION

This document describes version 0.002 of Text::Table::ASV (from Perl distribution Text-Table-ASV), released on 2021-02-20.

=head1 SYNOPSIS

 use Text::Table::ASV;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::TSV::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as ASV. This is basically a way to generate ASV
using the same interface as that of L<Text::Table::Tiny> (v0.03) or
L<Text::Table::Org>.

ASV (ASCII separated values, also sometimes DEL a.k.a. Delimited ASCII) is a
format similar to TSV (tab separated values). Instead of Tab character ("\t") as
the field separator, ASV uses "\x1f" (ASCII Unit Separator character) and
instead of newline ("\n") as the record separator, ASV uses "\x1e" (ASCII Record
Separator). There is currently no quoting or escaping mechanism provided.
"\x1c", "\x1d", "\x1e", and "\x1f" characters in cell will be replaced by
spaces.

The example shown in the SYNOPSIS generates the following table (the record
separator and unit separator are shown using "\x1f" and "\x1f" respectively):

 Name\x1fRank\x1fSerial\x1ealice\x1fpvt\x1f123456\x1ebob\x1fcpl\x1f98765321\x1ecarol\x1fbrig gen\x1f8745

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-ASV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-ASV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-Table-ASV/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

L<Bencher::Scenario::TextTableModules>.

L<https://en.wikipedia.org/wiki/Delimiter-separated_values>

L<https://en.wikipedia.org/wiki/C0_and_C1_control_codes#Field_separators>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
