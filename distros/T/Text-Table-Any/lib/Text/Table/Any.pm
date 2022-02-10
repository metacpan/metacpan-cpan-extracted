package Text::Table::Any;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(generate_table);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-23'; # DATE
our $DIST = 'Text-Table-Any'; # DIST
our $VERSION = '0.111'; # VERSION

our %BACKEND_FEATURES = (
    "Term::Table" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
    "Term::TablePrint" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
    "Text::ANSITable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
    },
    "Text::ASCIITable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
    "Text::FormatTable" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
    },
    "Text::MarkdownTable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
    "Text::Table" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
    },
    "Text::Table::ASV" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::CSV" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::HTML" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 1,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::HTML::DataTables" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 1,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::LTSV" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::Manifold" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
    "Text::Table::More" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::Org" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::Paragraph" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::Sprintf" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TickitWidget" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::Tiny" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TinyBorderStyle" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TinyColor" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TinyColorWide" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TinyWide" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::TSV" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::Table::XLSX" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
    },
    "Text::TabularDisplay" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
    },
    "Text::UnicodeBox::Table" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
    },
);

our @BACKENDS = sort keys %BACKEND_FEATURES;

sub _encode {
    my $val = shift;
    $val =~ s/([\\"])/\\$1/g;
    "\"$val\"";
}

sub backends {
    @BACKENDS;
}

sub generate_table {
    my %params = @_;

    my $rows          = $params{rows} or die "Must provide rows!";
    my $backend       = $params{backend} || 'Text::Table::Sprintf';
    my $header_row    = $params{header_row} // 1;
    my $separate_rows = $params{separate_rows} // 0;

    if ($backend eq 'Term::Table') {
        require Term::Table;
        my ($header, $data_rows);
        if ($header_row) {
            $header = $rows->[0];
            $data_rows = [ @{$rows}[1 .. $#{$rows}] ];
        } else {
            $header = [ map {"col$_"} 0..$#{$rows->[0]} ];
            $data_rows = $rows;
        }
        my $table = Term::Table->new(
            header => $header,
            rows   => $data_rows,
        );
        return join("\n", $table->render)."\n";
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
    } elsif ($backend eq 'Text::Table::ASV') {
        require Text::Table::ASV;
        return Text::Table::ASV::table(
            rows => $rows,
            header_row => $header_row,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::CSV') {
        require Text::Table::CSV;
        return Text::Table::CSV::table(
            rows => $rows,
            header_row => $header_row,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::HTML') {
        require Text::Table::HTML;
        return Text::Table::HTML::table(
            rows => $rows,
            header_row => $header_row,
            (caption => $params{caption}) x !!defined($params{caption}),
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::HTML::DataTables') {
        require Text::Table::HTML::DataTables;
        return Text::Table::HTML::DataTables::table(
            rows => $rows,
            header_row => $header_row,
            (caption => $params{caption}) x !!defined($params{caption}),
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::LTSV') {
        require Text::Table::LTSV;
        return Text::Table::LTSV::table(
            rows => $rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
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
    } elsif ($backend eq 'Text::Table::More') {
        require Text::Table::More;
        return Text::Table::More::generate_table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::Org') {
        require Text::Table::Org;
        return Text::Table::Org::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{caption}) ? (caption => $params{caption}) : (),
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::Paragraph') {
        require Text::Table::Paragraph;
        return Text::Table::Paragraph::table(
            rows => $rows,
            header_row => $header_row,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::Sprintf') {
        require Text::Table::Sprintf;
        return Text::Table::Sprintf::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::TickitWidget') {
        require Text::Table::TickitWidget;
        return Text::Table::TickitWidget::table(
            rows => $rows,
            header_row => $header_row,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::Tiny') {
        require Text::Table::Tiny;
        return Text::Table::Tiny::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyBorderStyle') {
        require Text::Table::TinyBorderStyle;
        return Text::Table::TinyBorderStyle::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColor') {
        require Text::Table::TinyColor;
        return Text::Table::TinyColor::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColorWide') {
        require Text::Table::TinyColorWide;
        return Text::Table::TinyColorWide::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyWide') {
        require Text::Table::TinyWide;
        return Text::Table::TinyWide::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TSV') {
        require Text::Table::TSV;
        return Text::Table::TSV::table(
            rows => $rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::XLSX') {
        require Text::Table::XLSX;
        return Text::Table::XLSX::table(
            rows => $rows,
            header_row => $header_row,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::TabularDisplay') {
        require Text::TabularDisplay;
        my $t = Text::TabularDisplay->new(@{ $rows->[0] });
        $t->add(@{ $rows->[$_] }) for 1..@$rows-1;
        return $t->render . "\n";
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
    } else {
        die "Unknown backend '$backend'";
    }
}

{
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    no warnings 'once';
    *table = \&generate_table;
}

1;
# ABSTRACT: Generate text table using one of several backends

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Any - Generate text table using one of several backends

=head1 VERSION

This document describes version 0.111 of Text::Table::Any (from Perl distribution Text-Table-Any), released on 2022-01-23.

=head1 SYNOPSIS

 use Text::Table::Any qw/generate_table/;

 my $rows = [
     # first element is header row
     ['Distribution', 'Author', 'First Version', 'Latest Version', 'Abstract'],

     # subsequent elements are data rows
     ['ACME-Dzil-Test-daemon', 'DAEMON', '0.001', '0.001', 'Module abstract placeholder text'],
     ['ACME-Dzil-Test-daemon2', 'DAEMON', '0.001', '0.001', 'Module abstract placeholder text'],
     ['Acme-CPANModules-ShellCompleters', 'PERLANCAR', '0.001', '0.001', 'Modules that provide shell tab completion for other commands/scripts'],
     ['Acme-CPANModules-WorkingWithURL', 'PERLANCAR', '0.001', '0.001', 'Working with URL'],
 ];

 print generate_table(rows => $rows);

will render the table using the default backend L<Text::Table::Sprintf> and
print something like:

 +----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------+
 | Distribution                     | Author    | First Version | Latest Version | Abstract                                                             |
 +----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------+
 | ACME-Dzil-Test-daemon            | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 | ACME-Dzil-Test-daemon2           | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 | Acme-CPANModules-ShellCompleters | PERLANCAR | 0.001         | 0.001          | Modules that provide shell tab completion for other commands/scripts |
 | Acme-CPANModules-WorkingWithURL  | PERLANCAR | 0.001         | 0.001          | Working with URL                                                     |
 +----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------+

To pick another backend:

 print generate_table(
     rows => $rows,
     backend => "Text::Table::Org",
 );

The result is something like:

 | Distribution                     | Author    | First Version | Latest Version | Abstract                                                             |
 |----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------|
 | ACME-Dzil-Test-daemon            | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 | ACME-Dzil-Test-daemon2           | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 | Acme-CPANModules-ShellCompleters | PERLANCAR | 0.001         | 0.001          | Modules that provide shell tab completion for other commands/scripts |
 | Acme-CPANModules-WorkingWithURL  | PERLANCAR | 0.001         | 0.001          | Working with URL                                                     |

To specify some other options:

 print generate_table(
     rows => $rows,
     header_row => 0,   # default is true
     separate_row => 1, # default is false
     caption => "Some of the new distributions released in Jan 2022",
     backend => "Text::Table::Org",
 );

The result is something like:

 #+CAPTION: Some of the new distributions released in Jan 2022
 | Distribution                     | Author    | First Version | Latest Version | Abstract                                                             |
 |----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------|
 | ACME-Dzil-Test-daemon            | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 |----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------|
 | ACME-Dzil-Test-daemon2           | DAEMON    | 0.001         | 0.001          | Module abstract placeholder text                                     |
 |----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------|
 | Acme-CPANModules-ShellCompleters | PERLANCAR | 0.001         | 0.001          | Modules that provide shell tab completion for other commands/scripts |
 |----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------|
 | Acme-CPANModules-WorkingWithURL  | PERLANCAR | 0.001         | 0.001          | Working with URL                                                     |

To pass backend-specific options:

 print generate_table(
     rows => $rows,
     backend => "Text::Table::More",
     backend_opts => {
         border_style => 'ASCII::SingleLineDoubleAfterHeader',
         align => 'right',
         row_attrs => [
             [0, {align=>'middle'}],
         ],
     },
 );

The result is something like:

 .----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------.
 |           Distribution           |  Author   | First Version | Latest Version |                               Abstract                               |
 +==================================+===========+===============+================+======================================================================+
 |            ACME-Dzil-Test-daemon |    DAEMON |         0.001 |          0.001 |                                     Module abstract placeholder text |
 |           ACME-Dzil-Test-daemon2 |    DAEMON |         0.001 |          0.001 |                                     Module abstract placeholder text |
 | Acme-CPANModules-ShellCompleters | PERLANCAR |         0.001 |          0.001 | Modules that provide shell tab completion for other commands/scripts |
 |  Acme-CPANModules-WorkingWithURL | PERLANCAR |         0.001 |          0.001 |                                                     Working with URL |
 `----------------------------------+-----------+---------------+----------------+----------------------------------------------------------------------'

=head1 DESCRIPTION

This module provides a single function, C<generate_table>, which formats a
two-dimensional array of data as text table, using one of several available
backends. The interface is modelled after L<Text::Table::Tiny>, but
L<Text::Table::Sprintf> is the default backend and although Text::Table::Tiny is
among the supported backends, it is not required by this module.

=head1 DIFFERENCES WITH TEXT::TABLE::TINY

=over

=item * 'top_and_tail' option from Text::Table::Tiny is not supported

Probably won't be supported. You can pass this option to Text::Table::Tiny
backend via L</backend_opts> option.

=item * 'align' option from Text::Table::Tiny is not supported

Will be supported in the future.

=item * 'style' option from Text::Table::Tiny is not supported

Won't be supported because this is specific to Text::Table::Tiny. If you want
custom border styles, here are some alternative backends you can use:
L<Text::Table::TinyBorderStyle>, L<Text::Table::More>,
L<Text::UnicodeBox::Table>.

=item * 'indent' option from Text::Table::Tiny is not supported

Probably won't be supported. You can indent a multiline string in Perl using
something like:

 $rendered_table =~ s/^/  /mg; # indent each line with two spaces

=item * 'compact' option from Text::Table::Tiny is not supported

May be supported in the future.

=back

=head1 VARIABLES

=head2 @BACKENDS

List of supported backends.

=head2 %BACKEND_FEATURES

List of features supported by each backend. Hash key is backend name, e.g.
C<Text::Table::Sprintf>. Hash value is a hashref containing feature name as
hashref key and a boolean value or other value as hashref value to describe the
support of that feature by that backend.

=head1 FUNCTIONS

=head2 table

An old name for L</generate_table> function (C<generate_table()> was not
available in Text::Table::Tiny < 0.04). This name is not available for export.

=head2 generate_table

Exportable.

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

=item * Term::Table

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

=item * Text::Table::TSV

=item * Text::Table::TickitWidget

=item * Text::Table::Tiny

=item * Text::Table::TinyBorderStyle

=item * Text::Table::TinyColor

=item * Text::Table::TinyColorWide

=item * Text::Table::TinyWide

=item * Text::Table::XLSX

=item * Text::TabularDisplay

=item * Text::UnicodeBox::Table

=back

Support matrix for each backend:

 +-------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+
 | backend                       | backend_opts | backend_opts_note                                                                              | caption | header_row | rows | separate_rows |
 +-------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+
 | Term::Table                   |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Term::TablePrint              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::ANSITable               |              |                                                                                                | 0       | 1          | 1    | 1             |
 | Text::ASCIITable              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::FormatTable             |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::MarkdownTable           |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::Table                   |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::Table::ASV              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::CSV              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::HTML             | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 1       | 1          | 1    | 0             |
 | Text::Table::HTML::DataTables | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 1       | 1          | 1    | 0             |
 | Text::Table::LTSV             | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 0          | 1    | 0             |
 | Text::Table::Manifold         |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::Table::More             | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::Org              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::Paragraph        | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::Sprintf          | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TSV              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 0          | 1    | 0             |
 | Text::Table::TickitWidget     | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::Tiny             | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyBorderStyle  | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyColor        | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyColorWide    | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyWide         | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::XLSX             | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::TabularDisplay          |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::UnicodeBox::Table       |              |                                                                                                | 0       | 1          | 1    | 0             |
 +-------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+

=item * rows

Required. Aoaos (array of array-of-scalars). Each element in the array is a row
of data, where each row is an array reference.

=item * header_row

Optional. Bool, default is true. If given a true value, the first row in the
data will be interpreted as a header row, and separated visually from the rest
of the table (e.g. with a ruled line). But some backends won't display
differently.

=item * separate_rows

Boolean. Optional. Default is false. If set to true, will draw a separator line
after each data row.

Not all backends support this.

=item * caption

Optional. Str. Caption of the table.

=item * backend_opts

Optional. Hashref. Pass backend-specific options to the backend module. Not all
backend modules support this, but all backend modules that have interface
following C<Text::Table::Tiny> should support this. Also note that as the list
of common options is expanded, a previously backend-specific option might be
available later as a common option.

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

This software is copyright (c) 2022, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
