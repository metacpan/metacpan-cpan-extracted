package Text::Table::HTML::DataTables;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-09'; # DATE
our $DIST = 'Text-Table-HTML-DataTables'; # DIST
our $VERSION = '0.009'; # VERSION

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub _escape_uri {
    require URI::Escape;
    URI::Escape::uri_escape(shift, "^A-Za-z0-9\-\._~/");
}

sub table {
    require File::ShareDir;
    require HTML::Entities;
    require JSON::PP;

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";
    my $default_length = int($params{default_length} // 1000);

    my $max_index = _max_array_index($rows);

    my $dist_dir = File::ShareDir::dist_dir('Text-Table-HTML-DataTables');

    # here we go...
    my @table;

    # load css/js
    push @table, "<html>\n";
    push @table, "<head>\n";

    push @table, qq(<title>).HTML::Entities::encode_entities($params{title}).qq(</title>\n) if defined $params{title};
    push @table, qq(<link rel="stylesheet" type="text/css" href="file://)._escape_uri("$dist_dir/datatables-1.10.22/datatables.css").qq(">\n);
    push @table, qq(<script src="file://)._escape_uri("$dist_dir/jquery-2.2.4/jquery-2.2.4.min.js").qq("></script>\n);
    push @table, qq(<script src="file://)._escape_uri("$dist_dir/datatables-1.10.22/datatables.js").qq("></script>\n);

    push @table, '<script>';
    my $dt_opts = {
        dom => 'lQfrtip',
        buttons => ['colvis', 'print'],
    };
    push @table, 'var dt_opts = ', JSON::PP::encode_json($dt_opts), '; ';
    push @table, '$(document).ready(function() { ', (
        '$("table").DataTable(dt_opts); ',
        '$("select[name=DataTables_Table_0_length]").val('.$default_length.'); ', # XXX element name should not be hardcoded, and this only works for the first datatable
        '$("select[name=DataTables_Table_0_length]").trigger("change"); ',        # doesn't get triggered automatically by previous line
    ), '});';
    push @table, '</script>'."\n\n";
    push @table, "</head>\n\n";

    push @table, "<body>\n";
    push @table, "<table>\n";
    push @table, qq(<caption>).HTML::Entities::encode_entities($params{title}).qq(</caption>\n) if defined $params{title};

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
        push @table, join(
	    "",
            "<tr>",
	    (map {(
                $in_header ? "<th>" : "<td>",
                _encode($row->[$_] // ''),
                $in_header ? "</th>" : "</td>",
            )} 0..$max_index),
            "</tr>\n",
	);
        if ($i == 0 && $params{header_row}) {
            push @table, "</thead>\n";
        }
    }

    push @table, "</tbody>\n";
    push @table, "</table>\n";
    push @table, "</body>\n\n";

    push @table, "</html>\n";

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

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return max( map { $#$_ } @$rows );
}

1;
# ABSTRACT: Generate HTML table with jQuery and DataTables plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::HTML::DataTables - Generate HTML table with jQuery and DataTables plugin

=head1 VERSION

This document describes version 0.009 of Text::Table::HTML::DataTables (from Perl distribution Text-Table-HTML-DataTables), released on 2021-12-09.

=head1 SYNOPSIS

 use Text::Table::HTML::DataTables;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123<456>'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::HTML::DataTables::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module is just like L<Text::Table::HTML>, except the HTML code will also
load jQuery (L<http://jquery.com>) and the DataTables plugin
(L<http://datatables.net>) from the local filesystem (distribution shared
directory), so you can filter and sort the table in the browser.

The datatables bundled in this distribution has the following characteristics:

=over

=item * Support negative search using dash prefix syntax ("-foo") a la Google

To search for table rows that contain "foo", "bar" (in no particular order) and
not "baz", you can enter in the search box:

 foo bar -baz

=back

The example shown in the SYNOPSIS generates HTML code like the following:

 <link rel="stylesheet" type="text/css" href="file:///home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.13/css/jquery.dataTables.min.css">
 <script src="file:///home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/auto/share/dist/Text-Table-HTML-DataTables/jquery-2.2.4/jquery-2.2.4.min.js"></script>
 <script src="file:///home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.13/js/jquery.dataTables.min.js"></script>
 <script>$(document).ready(function() { $("table").DataTable(); });</script>

 <table>
 <thead>
 <tr><th>Name</th><th>Rank</th><th>Serial</th></tr>
 </thead>
 <tbody>
 <tr><td>alice</td><td>pvt</td><td>12345</td></tr>
 <tr><td>bob</td><td>cpl</td><td>98765321</td></tr>
 <tr><td>carol</td><td>brig gen</td><td>8745</td></tr>
 </tbody>
 </table>

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these parameters, which are passed as a hash:

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=item * title

Optional. Str. If set, will output a HTML C<< <title> >> element in the HTML
head as well as table C<< <caption> >> element in the HTML body containing the
given title. The title will be HTML-encoded.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-HTML-DataTables>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-HTML-DataTables>.

=head1 SEE ALSO

L<Text::Table::HTML>

See also L<Bencher::Scenario::TextTableModules>.

L<https://datatables.net>

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

This software is copyright (c) 2021, 2020, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-HTML-DataTables>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
