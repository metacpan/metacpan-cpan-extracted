package Text::Table::HTML;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-11'; # DATE
our $DIST = 'Text-Table-HTML'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $max_index = _max_array_index($rows);

    # here we go...
    my @table;

    push @table, "<table>\n";

    # then the data
    my $i = -1;
    foreach my $row ( @{ $rows }[0..$#$rows] ) {
        $i++;
        my $in_header;
        if ($params{header_row}) {
            if ($i == 0) { push @table, "<thead>\n"; $in_header++ }
            if ($i == 1) { push @table, "<tbody>\n" }
        } else {
            if ($i == 1) { push @table, "<tbody>\n" }
        }
        push @table, "<tr>";
        for my $cell (@$row) {
            my $text    = ref $cell eq 'HASH' ? $cell->{text} : $cell;
            my $rowspan = int((ref $cell eq 'HASH' ? $cell->{rowspan} : undef) // 1);
            my $colspan = int((ref $cell eq 'HASH' ? $cell->{colspan} : undef) // 1);
            push @table,
                ($in_header ? "<th" : "<td"),
                ($rowspan > 1 ? " rowspan=$rowspan" : ""),
                ($colspan > 1 ? " colspan=$colspan" : ""),
                ">",
                _encode($text // ''),
                $in_header ? "</th>" : "</td>";
	}
        push @table, "</tr>\n";
        if ($i == 0 && $params{header_row}) {
            push @table, "</thead>\n";
        }
    }

    push @table, "</tbody>\n";
    push @table, "</table>\n";

    return join("", grep {$_} @table);
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
# ABSTRACT: Generate HTML table

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::HTML - Generate HTML table

=head1 VERSION

This document describes version 0.004 of Text::Table::HTML (from Perl distribution Text-Table-HTML), released on 2021-03-11.

=head1 SYNOPSIS

 use Text::Table::HTML;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123<456>'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::HTML::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as HTML table.

The example shown in the SYNOPSIS generates the following table:

 <table>
 <thead>
 <tr><th>Name</th><th>Rank</th><th>Serial</th></tr>
 </thead>
 <tbody>
 <tr><td>alice</td><td>pvt</td><td>123&lt;456&gt;</td></tr>
 <tr><td>bob</td><td>cpl</td><td>98765321</td></tr>
 <tr><td>carol</td><td>brig gen</td><td>8745</td></tr>
 </tbody>
 </table>

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference. And each array element is a string (cell
content) or hashref (with key C<text> to contain the cell text, and optionally
attributes too like C<rowspan>, C<colspan>).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-HTML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-Table-HTML/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

L<Text::Table::Any>

See also L<Bencher::Scenario::TextTableModules>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
