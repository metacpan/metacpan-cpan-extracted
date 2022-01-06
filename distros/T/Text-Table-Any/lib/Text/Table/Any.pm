## no critic: TestingAndDebugging::RequireUseStrict
package Text::Table::Any;

#IFUNBUILT
# # use 5.010001;
# # use strict;
# # use warnings;
#END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-09'; # DATE
our $DIST = 'Text-Table-Any'; # DIST
our $VERSION = '0.106'; # VERSION

our @BACKENDS = qw(
                      Term::TablePrint
                      Text::ANSITable
                      Text::ASCIITable
                      Text::FormatTable
                      Text::MarkdownTable
                      Text::Table
                      Text::Table::ASV
                      Text::Table::CSV
                      Text::Table::HTML
                      Text::Table::HTML::DataTables
                      Text::Table::LTSV
                      Text::Table::Manifold
                      Text::Table::More
                      Text::Table::Org
                      Text::Table::Paragraph
                      Text::Table::Sprintf
                      Text::Table::TickitWidget
                      Text::Table::Tiny
                      Text::Table::TinyBorderStyle
                      Text::Table::TinyColor
                      Text::Table::TinyColorWide
                      Text::Table::TinyWide
                      Text::Table::TSV
                      Text::Table::XLSX
                      Text::TabularDisplay
                      Text::UnicodeBox::Table
              );

sub _encode {
    my $val = shift;
    $val =~ s/([\\"])/\\$1/g;
    "\"$val\"";
}

sub backends {
    @BACKENDS;
}

sub table {
    my %params = @_;

    my $rows          = $params{rows} or die "Must provide rows!";
    my $backend       = $params{backend} || 'Text::Table::Sprintf';
    my $header_row    = $params{header_row} // 1;
    my $separate_rows = $params{separate_rows} // 0;

    if ($backend eq 'Text::Table::TickitWidget') {
        require Text::Table::TickitWidget;
        return Text::Table::TickitWidget::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::Tiny') {
        require Text::Table::Tiny;
        return Text::Table::Tiny::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyBorderStyle') {
        require Text::Table::TinyBorderStyle;
        return Text::Table::TinyBorderStyle::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColor') {
        require Text::Table::TinyColor;
        return Text::Table::TinyColor::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColorWide') {
        require Text::Table::TinyColorWide;
        return Text::Table::TinyColorWide::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyWide') {
        require Text::Table::TinyWide;
        return Text::Table::TinyWide::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::More') {
        require Text::Table::More;
        return Text::Table::More::generate_table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::Sprintf') {
        require Text::Table::Sprintf;
        return Text::Table::Sprintf::table(
            rows => $rows,
            header_row => $header_row,
        ) . "\n";
    } elsif ($backend eq 'Text::Table::Org') {
        require Text::Table::Org;
        return Text::Table::Org::table(
            rows => $rows,
            header_row => $header_row,
        );
    } elsif ($backend eq 'Text::Table::CSV') {
        require Text::Table::CSV;
        return Text::Table::CSV::table(
            rows => $rows,
            header_row => $header_row,
        );
    } elsif ($backend eq 'Text::Table::TSV') {
        require Text::Table::TSV;
        return Text::Table::TSV::table(
            rows => $rows,
        );
    } elsif ($backend eq 'Text::Table::LTSV') {
        require Text::Table::LTSV;
        return Text::Table::LTSV::table(
            rows => $rows,
        );
    } elsif ($backend eq 'Text::Table::ASV') {
        require Text::Table::ASV;
        return Text::Table::ASV::table(
            rows => $rows,
            header_row => $header_row,
        );
    } elsif ($backend eq 'Text::Table::HTML') {
        require Text::Table::HTML;
        return Text::Table::HTML::table(
            rows => $rows,
            header_row => $header_row,
            (title => $params{title}) x !!defined($params{title}),
        );
    } elsif ($backend eq 'Text::Table::HTML::DataTables') {
        require Text::Table::HTML::DataTables;
        return Text::Table::HTML::DataTables::table(
            rows => $rows,
            header_row => $header_row,
            (title => $params{title}) x !!defined($params{title}),
        );
    } elsif ($backend eq 'Text::Table::Paragraph') {
        require Text::Table::Paragraph;
        return Text::Table::Paragraph::table(
            rows => $rows,
            header_row => $header_row,
        );
    } elsif ($backend eq 'Text::ANSITable') {
        require Text::ANSITable;
        my $t = Text::ANSITable->new(
            use_utf8 => 0,
            use_box_chars => 0,
            use_color => 0,
            border_style => 'ASCII::SingleLine',
        );
        # XXX pick an appropriate border style when header_row=0
        if ($header_row) {
            $t->columns($rows->[0]);
            $t->add_row($rows->[$_]) for 1..@$rows-1;
        } else {
            $t->columns([ map {"col$_"} 0..$#{$rows->[0]} ]);
            $t->add_row($_) for @$rows;
        }
        $t->show_row_separator(1) if $separate_rows;
        return $t->draw;
    } elsif ($backend eq 'Text::Table::Manifold') {
        require Text::Table::Manifold;
        my $t = Text::Table::Manifold->new;
        if ($header_row) {
            $t->headers($rows->[0]);
            $t->data([ @{$rows}[1 .. $#{$rows}] ]);
        } else {
            $t->headers([ map {"col$_"} 0..$#{$rows->[0]} ]);
            $t->data($rows);
        }
        return join("\n", @{$t->render(padding => 1)}) . "\n";
    } elsif ($backend eq 'Text::UnicodeBox::Table') {
        require Text::UnicodeBox::Table;
        my $t = Text::UnicodeBox::Table->new;
        if ($header_row) {
            $t->add_header(@{ $rows->[0] });
            $t->add_row(@{ $rows->[$_] }) for 1 .. $#{$rows};
        } else {
            $t->add_header(map {"col$_"} 0..$#{$rows->[0]});
            $t->add_row(@{ $rows->[$_] }) for 0 .. $#{$rows};
        }
        return $t->render;
    } elsif ($backend eq 'Text::ASCIITable') {
        require Text::ASCIITable;
        my $t = Text::ASCIITable->new();
        if ($header_row) {
            $t->setCols(@{ $rows->[0] });
            $t->addRow(@{ $rows->[$_] }) for 1..@$rows-1;
        } else {
            $t->setCols(map { "col$_" } 0..$#{ $rows->[0] });
            $t->addRow(@$_) for @$rows;
        }
        return "$t";
    } elsif ($backend eq 'Text::FormatTable') {
        require Text::FormatTable;
        my $t = Text::FormatTable->new(join('|', ('l') x @{ $rows->[0] }));
        $t->head(@{ $rows->[0] });
        $t->row(@{ $rows->[$_] }) for 1..@$rows-1;
        return $t->render;
    } elsif ($backend eq 'Text::MarkdownTable') {
        require Text::MarkdownTable;
        my $out = "";
        my $fields =  $header_row ?
            $rows->[0] : [map {"col$_"} 0..$#{ $rows->[0] }];
        my $t = Text::MarkdownTable->new(file => \$out, columns => $fields);
        foreach (($header_row ? 1:0) .. $#{$rows}) {
            my $row = $rows->[$_];
            $t->add( {
                map { $fields->[$_] => $row->[$_] } 0..@$fields-1
            });
        }
        $t->done;
        return $out;
    } elsif ($backend eq 'Text::Table') {
        require Text::Table;
        my $t = Text::Table->new(@{ $rows->[0] });
        $t->load(@{ $rows }[1..@$rows-1]);
        return $t;
    } elsif ($backend eq 'Text::TabularDisplay') {
        require Text::TabularDisplay;
        my $t = Text::TabularDisplay->new(@{ $rows->[0] });
        $t->add(@{ $rows->[$_] }) for 1..@$rows-1;
        return $t->render . "\n";
    } elsif ($backend eq 'Text::Table::XLSX') {
        require Text::Table::XLSX;
        return Text::Table::XLSX::table(
            rows => $rows, header_row => $header_row);
    } elsif ($backend eq 'Term::TablePrint') {
        require Term::TablePrint;
        my $rows2;
        if ($header_row) {
            $rows2 = $rows;
        } else {
            $rows2 = [@$rows];
            shift @$rows2;
        }
        return Term::TablePrint::print_table($rows);
    } else {
        die "Unknown backend '$backend'";
    }
}

1;
# ABSTRACT: Generate text table using one of several backends

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Any - Generate text table using one of several backends

=head1 VERSION

This document describes version 0.106 of Text::Table::Any (from Perl distribution Text-Table-Any), released on 2021-12-09.

=head1 SYNOPSIS

 use Text::Table::Any;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::Any::table(rows => $rows, header_row => 1,
                               backend => 'Text::Table::More');

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as text table, using one of several available
backends. The interface is modelled after L<Text::Table::Tiny> (0.03).
L<Text::Table::Sprintf> is the default backend.

The example shown in the SYNOPSIS generates the following table:

 +-------+----------+----------+
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |
 +-------+----------+----------+

When using C<Text::Table::Org> backend, the result is something like:

 | Name  | Rank     | Serial   |
 |-------+----------+----------|
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |

When using C<Text::Table::CSV> backend:

 "Name","Rank","Serial"
 "alice","pvt","123456"
 "bob","cpl","98765321"
 "carol","brig gen","8745"

When using C<Text::ANSITable> backend:

 .-------+----------+----------.
 | Name  | Rank     |   Serial |
 +-------+----------+----------+
 | alice | pvt      |   123456 |
 | bob   | cpl      | 98765321 |
 | carol | brig gen |     8745 |
 `-------+----------+----------'

When using C<Text::ASCIITable> backend:

 .-----------------------------.
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      |   123456 |
 | bob   | cpl      | 98765321 |
 | carol | brig gen |     8745 |
 '-------+----------+----------'

When using C<Text::FormatTable> backend:

 Name |Rank    |Serial
 alice|pvt     |123456
 bob  |cpl     |98765321
 carol|brig gen|8745

When using C<Text::MarkdownTable> backend:

 | Name  | Rank     | Serial   |
 |-------|----------|----------|
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |

When using C<Text::Table> backend:

 Name  Rank     Serial
 alice pvt        123456
 bob   cpl      98765321
 carol brig gen     8745

When using C<Text::TabularDisplay> backend:

 +-------+----------+----------+
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |
 +-------+----------+----------+

=head1 VARIABLES

=head2 @BACKENDS

List of supported backends.

=head1 FUNCTIONS

=head2 table

Usage:

 table(%params) => str

Except for the C<backend> parameter, the parameters will mostly be passed to the
backend, sometimes slightly modified if necessary to achieve the desired effect.
If a parameter is not supported by a backend, then it will not be passed to the
backend.

Known parameters:

=over

=item * backend

Optional. Str, default C<Text::Table::Sprintf>. Pick a backend module. Supported
backends:

=over

=item * Term::TablePrint

=item * Text::ANSITable

=item * Text::ASCIITable

=item * Text::FormatTable

=item * Text::MarkdownTable

=item * Text::Table

=item * Text::Table::ASV

=item * Text::Table::CSV

=item * Text::Table::HTML

=item * Text::Table::HTML::DataTables

=item * Text::Table::LTSV

=item * Text::Table::Manifold

=item * Text::Table::More

=item * Text::Table::Org

=item * Text::Table::Paragraph

=item * Text::Table::Sprintf

=item * Text::Table::TickitWidget

=item * Text::Table::Tiny

=item * Text::Table::TinyBorderStyle

=item * Text::Table::TinyColor

=item * Text::Table::TinyColorWide

=item * Text::Table::TinyWide

=item * Text::Table::TSV

=item * Text::Table::XLSX

=item * Text::TabularDisplay

=item * Text::UnicodeBox::Table

=back

=item * rows

Required. Aoaos (array of array-of-scalars). Each element in the array is a row
of data, where each row is an array reference.

=item * header_row

Optional. Bool, default is false. If given a true value, the first row in the
data will be interpreted as a header row, and separated visually from the rest
of the table (e.g. with a ruled line). But some backends won't display
differently.

=item * separate_rows

Boolean. Optional. Default is false. If set to true, will draw a separator line
after each data row.

Not all backends support this.

=item * title

Optional. Str. Title of the table.

Currently the only backends supporting this are C<Text::Table::HTML> and
C<Text::Table::HTML::DataTables>.

=back

=head2 backends

Return list of supported backends. You can also get the list from the
L</@BACKENDS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Any>.

=head1 SEE ALSO

L<Acme::CPANModules::TextTable>

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
