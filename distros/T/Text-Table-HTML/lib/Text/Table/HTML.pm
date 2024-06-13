package Text::Table::HTML;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'Text-Table-HTML'; # DIST
our $VERSION = '0.011'; # VERSION

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub table {
    my %params = @_;
    my $rows   = delete $params{rows} or die "Must provide rows!";

    # here we go...
    my @table;

    my %attr = %{ delete( $params{html_attr} ) // {} };
    {
        my @direct_attr = grep exists $params{"html_$_"}, qw( id class style );
        $attr{@direct_attr} = delete @params{ map "html_$_", @direct_attr };
    }

    my $attr =
      keys %attr
      ? join q{ }, '', map { qq{$_="$attr{$_}"} } grep defined( $attr{$_} ),
      keys %attr
      : '';

    # set all rows bottom_border if requested.
    my $bottom_border_rows = delete($params{separate_rows});

    push @table, "<table$attr>\n";

    if ( defined( my $caption = delete $params{caption} ) ) {
        push @table, "<caption>" . _encode($caption) . "</caption>\n";
    }

    if ( defined( my $colgroup = delete $params{html_colgroup} ) ) {

        if (@$colgroup) {
            push @table, "<colgroup>\n";

            for my $col ( @{$colgroup} ) {

                my @element = '<col';
                if ( defined $col ) {
                    if ( 'HASH' eq ref $col ) {
                        push @element, qq{$_="$col->{$_}"} for keys %{$col};
                    }
                    else {
                        push @element, $col;
                    }
                }
                push @element, '/>';
                push @table, join( q{ }, @element ), "\n";
            }

            push @table, "</colgroup>\n";
        }
    }

    # then the header & footer
    my $header_row = delete $params{header_row} // 0;
    my $footer_row = delete $params{footer_row} // 0;

    # check for unrecognized options
    die( "unrecognized options: ", join q{, }, sort keys %params )
      if keys %params;

    my $footer_row_start;
    my $footer_row_end;

    # footer is directly after the header
    if ( $footer_row > 0 ) {
        $footer_row_start = $header_row;
        $footer_row_end   = $footer_row_start + $footer_row;
        $footer_row       = !!1;
    }

    # footer is at end
    elsif ( $footer_row < 0 ) {
        $footer_row_start = @{$rows} + $footer_row;
        $footer_row_end   = $footer_row_start - $footer_row;
        $footer_row       = !!1;
    }

    my $needs_thead_open  = !!$header_row;
    my $needs_thead_close = !!0;

    my $needs_tbody_open  = !!1;
    my $add_tbody_open    = !!1;
    my $needs_tbody_close = !!0;

    my $needs_tfoot_close = !!0;
    my $idx               = -1;

    # then the data
    foreach my $row ( @{$rows} ) {
        ++$idx;

        my $col_tag = 'td';

        if ($header_row) {

            $col_tag = 'th';

            if ($needs_thead_open) {
                push @table, "<thead>\n";
                $needs_thead_open  = !!0;
                $needs_thead_close = !!1;
                $add_tbody_open    = !!0;
            }

            elsif ( --$header_row == 0 ) {
                push @table, "</thead>\n";
                $needs_thead_close = !!0;
                $add_tbody_open    = $needs_tbody_open;
                $col_tag           = 'td';
            }
        }

        if ($footer_row) {

            if ( $idx == $footer_row_start ) {

                if ($needs_thead_close) {
                    push @table, "</thead>\n";
                    $needs_thead_close = !!0;
                }

                elsif ($needs_tbody_close) {
                    push @table, "</tbody>\n";
                    $needs_tbody_close = !!0;
                }

                push @table, "<tfoot>\n";
                $add_tbody_open    = !!0;
                $needs_tfoot_close = !!1;
            }

            elsif ( $idx == $footer_row_end ) {
                push @table, "</tfoot>\n";
                $footer_row     = $needs_tfoot_close = !!0;
                $add_tbody_open = $needs_tbody_open;
            }

        }

        if ($add_tbody_open) {
            push @table, "<tbody>\n";
            $add_tbody_open    = $needs_tbody_open = !!0;
            $needs_tbody_close = !!1;
        }

        my $bottom_border;

        my @row;

        for my $cell (@$row) {

            my $cell_tag = $col_tag;
            my $text;
            my $tag  = $col_tag;
            my $attr = '';

            if ( ref $cell eq 'HASH' ) {

                # add a class attribute for bottom_border if
                # any cell in the row has it set. once the attribute is set,
                # no need to do the check again.
                $bottom_border //=
                  ( $bottom_border_rows || $cell->{bottom_border} || undef )
                  && " class=has_bottom_border";

                if ( defined $cell->{raw_html} ) {
                    $text = $cell->{raw_html};
                }
                else {
                    $text = _encode( $cell->{text} // '' );
                }

                my $rowspan = int( $cell->{rowspan} // 1 );
                $attr .= " rowspan=$rowspan" if $rowspan > 1;

                my $colspan = int( $cell->{colspan} // 1 );
                $attr .= " colspan=$colspan" if $colspan > 1;

                $attr .= ' align="' . $cell->{align} . '"'
                  if defined $cell->{align};

                $cell_tag = $cell->{html_element}
                  if defined $cell->{html_element};

                if ( defined $cell->{html_scope} ) {
                    die("'html_scope' attribute is only valid in header cells")
                      unless $col_tag eq 'th';
                    $attr .= ' scope="' . $cell->{html_scope} . '"';
                }

                # cleaner if in a loop, but that might slow things down
                $attr .= ' class="' . $cell->{html_class} . '"'
                  if defined $cell->{html_class};
                $attr .= ' headers="' . $cell->{html_headers} . '"'
                  if defined $cell->{html_headers};
                $attr .= ' id="' . $cell->{html_id} . '"'
                  if defined $cell->{html_id};
                $attr .= ' style="' . $cell->{html_style} . '"'
                  if defined $cell->{html_style};
            }
            else {
                $text = _encode( $cell // '' );
            }

            push @row,
              '<' . $cell_tag . $attr . '>', $text, '</' . $cell_tag . '>';
        }

        push @table, "<tr" . ( $bottom_border // '' ) . ">", @row, "</tr>\n";
    }

    push @table, "</thead>\n" if $needs_thead_close;
    push @table, "</tfoot>\n" if $needs_tfoot_close;

    push @table, "<tbody>\n"  if $needs_tbody_open;
    push @table, "</tbody>\n" if $needs_tbody_open || $needs_tbody_close;
    push @table, "</table>\n";

    return join( "", grep { $_ } @table );
}

1;

# ABSTRACT: Generate HTML table

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::HTML - Generate HTML table

=head1 VERSION

This document describes version 0.011 of Text::Table::HTML (from Perl distribution Text-Table-HTML), released on 2024-06-13.

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
two-dimensional array of data as HTML table. Its interface was first modelled
after L<Text::Table::Tiny> 0.03.

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

Required. Array of array of (scalars or hashrefs). One or more rows of
data, where each row is an array reference. Each array element is
a string (cell content) or hashref (with key C<text> to contain the
cell text or C<raw_html> to contain the cell's raw HTML which won't be
escaped further), and optionally other cell and HTML attributes:
C<align>,
C<bottom_border>,
C<colspan>,
C<html_class>,
C<html_element>,
C<html_headers>,
C<html_id>,
C<html_scope>,
C<html_style>,
C<rowspan>
).

The C<html_element> attribute specifies the name of the HTML element
to use for that cell. It defaults to C<th> for header rows and C<td> for data rows.

If the C<bottom_border> attribute is set, the row element will have a
class attribute of C<has_bottom_border>.

For example,

  header_row => 1,
  rows =>
    [ [ '&nbsp', 'January', 'December' ],
      [ { html_element => 'th', text => 'Boots' } , 20, 30 ],
      [ { html_element => 'th', text => 'Frocks' } , 40, 50 ],
    ]

generates a table where each entry in the first row is a header
element, and the first entry in subsequent rows is an element.

=item * caption

Optional. Str. If set, will add an HTML C<< <caption> >> element to set the
table caption.

=item * header_row

Optional. Integer. Default 0. Whether we should add header row(s) (rows inside
C<< <thead> >> instead of C<< <tbody> >>). Support multiple header rows; you can
set this argument to an integer larger than 1.

=item * footer_row

Optional. Integer. Default 0. Whether we should add footer row(s)
(rows inside C<< <tfoot> >> instead of C<< <tbody> >>). Supports
multiple footer rows.

=over

=item *

If the footer rows are found immediately after the header rows (if
any) in the C<rows> array, set C<footer_row> to the number of rows.

=item *

If the footer rows are the last rows in C<rows>, set C<footer_row> to
the I<negative> number of rows.

=back

=item * separate_rows

Boolean. Optional. Default 0.  If set to true is equivalent to
setting the C<bottom_border> attribute for each row.

=item * html_colgroup

Optional. An array of scalars or hashes which define a C<colgroup> block.

The array should contain one entry per column or per span of
columns.  Each entry will result in a new C<col> element, with the following
mapping:

=over

=item * undefined

If an entry is C<undef>,then an empty C<col> element will be added.

=item * hash

A hash is translated into element attributes named after
its keys.

Empty hashes result in an empty C<col> element.

=item * scalars

A scalar must be a string containig a complete specification of an attribute,
and is inserted verbatim into the element.

=back

For example,

  html_colgroup => [ undef, {}, q{span="2"}, { class => 'batman' } ]

results in

  <colgroup>
  <col/>
  <col/>
  <col span="2" />
  <col class="batman" />
  </colgroup>

=item * html_attr

Optional. Hash.  The hash entries are added as attributes to the C<table> HTML element.

=item * html_id

Optional. Scalar.  The I<table> element's I<id> attribute.

=item * html_class

Optional. Scalar.  The I<table> element's I<class> attribute.

=item * html_style

Optional. Scalar.  The I<table> element's I<style> attribute.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
