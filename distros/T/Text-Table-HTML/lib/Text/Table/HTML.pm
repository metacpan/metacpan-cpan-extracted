package Text::Table::HTML;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-05-22'; # DATE
our $DIST = 'Text-Table-HTML'; # DIST
our $VERSION = '0.010'; # VERSION

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    # here we go...
    my @table;

    push @table, "<table>\n";

    if (defined $params{caption}) {
        push @table, "<caption>"._encode($params{caption})."</caption>\n";
    }

    # then the data
    my $header_row   = $params{header_row} // 0;
    my $needs_thead = !!$header_row;
    my $needs_tbody = !!1;
    foreach my $row ( @{$rows} ) {

        my $coltag = 'td';

        if ($header_row ) {
            $coltag = 'th';

            if ($needs_thead) {
                push @table, "<thead>\n";
                $needs_thead = !!0;
            }
        }

        elsif ($needs_tbody) {
            push @table, "<tbody>\n";
            $needs_tbody = !!0;
        }

        my $bottom_border;

        my @row;

        for my $cell (@$row) {

            my $text;
            my $attr = '';

            if (ref $cell eq 'HASH') {

                # add a class attribute for bottom_border if
                # any cell in the row has it set. once the attribute is set,
                # no need to do the check again.
                $bottom_border //=
                  ($cell->{bottom_border} || undef) && " class=has_bottom_border";

                if (defined $cell->{raw_html}) {
                    $text = $cell->{raw_html};
                } else {
                    $text = _encode( $cell->{text} // '' );
                }

                my $rowspan = int($cell->{rowspan}  // 1);
                $attr .= " rowspan=$rowspan" if $rowspan > 1;

                my $colspan = int($cell->{colspan}  // 1);
                $attr .= " colspan=$colspan" if $colspan > 1;

                $attr .= ' align="' . $cell->{align} . '"' if defined $cell->{align};
            }
            else {
                $text = _encode( $cell // '' );
            }

            push @row,
              '<' . $coltag . $attr . '>', $text, '</' . $coltag . '>';
	}

        push @table,
          "<tr". ( $bottom_border // '' ) .">",
          @row,
          "</tr>\n";

        if ( $header_row && $header_row-- == 1 ) {
            push @table, "</thead>\n";
        }
    }

    push @table, "<tbody>\n" if $needs_tbody;
    push @table, "</tbody>\n";
    push @table, "</table>\n";

    return join("", grep {$_} @table);
}

1;
# ABSTRACT: Generate HTML table

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::HTML - Generate HTML table

=head1 VERSION

This document describes version 0.010 of Text::Table::HTML (from Perl distribution Text-Table-HTML), released on 2023-05-22.

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
two-dimensional array of data as HTML table. Its interface is modelled after
L<Text::Table::Tiny> 0.03.

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

=head1 COMPATIBILITY NOTES WITH TEXT::TABLE::TINY

In C<Text::Table::HTML>, C<header_row> is an integer instead of boolean. It
supports multiple header rows.

Cells in C<rows> can be hashrefs instead of scalars.

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows

Required. Array of array of (scalars or hashrefs). One or more rows of data,
where each row is an array reference. And each array element is a string (cell
content) or hashref (with key C<text> to contain the cell text or C<raw_html> to
contain the cell's raw HTML which won't be escaped further), and optionally
other attributes: C<rowspan>, C<colspan>, C<align>, C<bottom_border>).

=item * caption

Optional. Str. If set, will add an HTML C<< <caption> >> element to set the
table caption.

=item * header_row

Optional. Integer. Default 0. Whether we should add header row(s) (rows inside
C<< <thead> >> instead of C<< <tbody> >>). Support multiple header rows; you can
set this argument to an integer larger than 1.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-HTML>.

=head1 SEE ALSO

L<Text::Table::HTML::DataTables>

L<Text::Table::Any>

L<Bencher::Scenario::TextTableModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Diab Jerius

Diab Jerius <djerius@cfa.harvard.edu>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
