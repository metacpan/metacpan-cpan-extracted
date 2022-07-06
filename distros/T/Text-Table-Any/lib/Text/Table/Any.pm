package Text::Table::Any;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(generate_table);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-03'; # DATE
our $DIST = 'Text-Table-Any'; # DIST
our $VERSION = '0.115'; # VERSION

our %BACKEND_FEATURES = (
    "Term::Table" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 0,
    },
    "Term::TablePrint" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 0,
    },
    "Text::ANSITable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        align => 1,
    },
    "Text::ASCIITable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 1,
    },
    "Text::FormatTable" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        align => 1,
        align_note => "c(enter) alignment is not supported, will fallback to l(eft)",
    },
    "Text::MarkdownTable" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 0,
    },
    "Text::Table" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        align => 1,
    },
    "Text::Table::ASV" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::CSV" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::HTML" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 1,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::HTML::DataTables" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 1,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::LTSV" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::Manifold" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 1,
    },
    "Text::Table::More" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 1,
    },
    "Text::Table::Org" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 1,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::Paragraph" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::Sprintf" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "",
    },
    "Text::Table::TickitWidget" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::Tiny" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 1,
    },
    "Text::Table::TinyBorderStyle" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::TinyColor" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::TinyColorWide" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::TinyWide" => {
        rows => 1,
        header_row => 1,
        separate_rows => 1,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
        align_note => "TODO, backend does not support yet, parameter already passed",
    },
    "Text::Table::TSV" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::Table::XLSX" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        backend_opts => 1,
        backend_opts_note => "Backend-specific options (backend_opts) will be passed to table() or generate_table() directly",
        align => 0,
    },
    "Text::TabularDisplay" => {
        rows => 1,
        header_row => 0,
        separate_rows => 0,
        caption => 0,
        align => 0,
    },
    "Text::UnicodeBox::Table" => {
        rows => 1,
        header_row => 1,
        separate_rows => 0,
        caption => 0,
        align => 0,
        align_note => "TODO: backend supports left/right",
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
    my $header_row    = $params{header_row} // 0;
    my $separate_rows = $params{separate_rows} // 0;
    my $align         = $params{align};

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
            ($align && !ref($align) ? (cell_align => ($align eq 'r' ? 'right' : $align eq 'c' ? 'middle' : 'left')) : ()),
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
        if (ref $align) {
            for my $i (0 .. @{$rows->[0]}-1) {
                my $col_align = $align->[$i];
                next unless $col_align;
                $t->set_column_style($i, align => ($col_align eq 'r' ? 'right' : $col_align eq 'c' ? 'middle' : 'left'));
            }
        }
        return $t->draw;
    } elsif ($backend eq 'Text::ASCIITable') {
        require Text::ASCIITable;
        my $t = Text::ASCIITable->new();
        my @colnames;
        if ($header_row) {
            @colnames = @{ $rows->[0] };
            $t->setCols(@colnames);
            $t->addRow(@{ $rows->[$_] }) for 1..@$rows-1;
        } else {
            @colnames = map { "col$_" } 0..$#{ $rows->[0] };
            $t->setCols(@colnames);
            $t->addRow(@$_) for @$rows;
        }
        if ($align) {
            for my $i (ref $align ? (0 .. $#{$align}) : (0 .. @colnames-1)) {
                my $colname = $colnames[$i];
                my $col_align = ref $align ? $align->[$i] : $align;
                my $align_val = ($col_align eq 'r' ? 'right' : $col_align eq 'c' ? 'center' : 'left');
                #say "D:aligning col: $colname -> $align_val";
                $t->alignCol($colname, $align_val);
            }
        }
        return "$t";
    } elsif ($backend eq 'Text::FormatTable') {
        require Text::FormatTable;
        my @formats = ('l') x @{ $rows->[0] };
        if ($align) {
            if (ref $align) {
                for my $i (0 .. @{$align}-1) {
                    my $col_align = $align->[$i];
                    $formats[$i] = $col_align eq 'r' ? 'r' : 'l';
                }
            } else {
                @formats = ($align eq 'r' ? 'r' : 'l') x @{ $rows->[0] };
            }
        }
        #use DD; dd \@formats;
        my $t = Text::FormatTable->new(join('|', @formats));
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
        my @colspecs;
        for my $i (0 .. @{ $rows->[0] }-1) {
            push @colspecs, {
                title => $rows->[0][$i],
            };
        }
        if ($align) {
            if (ref $align) {
                for my $i (0 .. @{$align}-1) {
                    my $col_align = $align->[$i];
                    $colspecs[$i]{align} = $col_align eq 'r' ? 'right' : $col_align eq 'c' ? 'center' : 'left';
                    $colspecs[$i]{align_title} = $colspecs[$i]{align};
                }
            } else {
                for my $i (0 .. @{ $rows->[0] }-1) {
                    $colspecs[$i]{align} = $align eq 'r' ? 'right' : $align eq 'c' ? 'center' : 'left';
                    $colspecs[$i]{align_title} = $colspecs[$i]{align};
                }
            }
        }
        #use DD; dd \@colspecs;
        my $t = Text::Table->new(@colspecs);
        $t->load(@{ $rows }[1..@$rows-1]);
        return "$t";
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
            ($align ? (align => $align) : ()),
        );
    } elsif ($backend eq 'Text::Table::HTML::DataTables') {
        require Text::Table::HTML::DataTables;
        return Text::Table::HTML::DataTables::table(
            rows => $rows,
            header_row => $header_row,
            (caption => $params{caption}) x !!defined($params{caption}),
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
            ($align ? (align => $align) : ()),
        );
    } elsif ($backend eq 'Text::Table::LTSV') {
        require Text::Table::LTSV;
        return Text::Table::LTSV::table(
            rows => $rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
    } elsif ($backend eq 'Text::Table::Manifold') {
        require Text::Table::Manifold;
        my @ttm_args;
        if ($align) {
            my @aligns;
            if (ref $align) {
                for my $i (0 .. @{$align}-1) {
                    my $col_align = $align->[$i];
                    push @aligns, $col_align eq 'r' ? Text::Table::Manifold::align_right() : $col_align eq 'c' ? Text::Table::Manifold::align_center() : Text::Table::Manifold::align_left();
                }
            } else {
                for my $i (0 .. @{ $rows->[0] }-1) {
                    my $col_align = $align;
                    push @aligns, $col_align eq 'r' ? Text::Table::Manifold::align_right() : $col_align eq 'c' ? Text::Table::Manifold::align_center() : Text::Table::Manifold::align_left();
                }
            }
            push @ttm_args, alignment => \@aligns;
        }
        my $t = Text::Table::Manifold->new(@ttm_args);
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
        my @ttm_args = (
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
        );
        if ($align) {
            if (ref $align) {
                my @col_attrs;
                for my $i (0 .. @$align-1) {
                    my $col_align = $align->[$i];
                    push @col_attrs, [$i, {align=>($col_align eq 'r' ? 'right' : $col_align eq 'c' ? 'middle' : 'left')}];
                }
                push @ttm_args, col_attrs => \@col_attrs;
            } else {
                push @ttm_args, align => ($align eq 'r' ? 'right' : $align eq 'c' ? 'middle' : 'left');
            }
        }
        return Text::Table::More::generate_table(@ttm_args);
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
            $align ? (align => $align) : (),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyBorderStyle') {
        require Text::Table::TinyBorderStyle;
        return Text::Table::TinyBorderStyle::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
            ($align ? (align => $align) : ()),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColor') {
        require Text::Table::TinyColor;
        return Text::Table::TinyColor::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
            ($align ? (align => $align) : ()),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyColorWide') {
        require Text::Table::TinyColorWide;
        return Text::Table::TinyColorWide::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
            ($align ? (align => $align) : ()),
        ) . "\n";
    } elsif ($backend eq 'Text::Table::TinyWide') {
        require Text::Table::TinyWide;
        return Text::Table::TinyWide::table(
            rows => $rows,
            header_row => $header_row,
            separate_rows => $separate_rows,
            defined($params{backend_opts}) ? %{$params{backend_opts}} : (),
            ($align ? (align => $align) : ()),
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

This document describes version 0.115 of Text::Table::Any (from Perl distribution Text-Table-Any), released on 2022-07-03.

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

=item * 'style' option from Text::Table::Tiny is not supported

Won't be supported because this is specific to Text::Table::Tiny. If you want
custom border styles, here are some alternative backends you can use:
L<Text::ANSITable>, L<Text::Table::TinyBorderStyle>, L<Text::Table::More>,
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

=item * L<Term::Table>

=item * L<Term::TablePrint>

=item * L<Text::ANSITable>

=item * L<Text::ASCIITable>

=item * L<Text::FormatTable>

=item * L<Text::MarkdownTable>

=item * L<Text::Table>

=item * L<Text::Table::ASV>

=item * L<Text::Table::CSV>

=item * L<Text::Table::HTML>

=item * L<Text::Table::HTML::DataTables>

=item * L<Text::Table::LTSV>

=item * L<Text::Table::Manifold>

=item * L<Text::Table::More>

=item * L<Text::Table::Org>

=item * L<Text::Table::Paragraph>

=item * L<Text::Table::Sprintf>

=item * L<Text::Table::TSV>

=item * L<Text::Table::TickitWidget>

=item * L<Text::Table::Tiny>

=item * L<Text::Table::TinyBorderStyle>

=item * L<Text::Table::TinyColor>

=item * L<Text::Table::TinyColorWide>

=item * L<Text::Table::TinyWide>

=item * L<Text::Table::XLSX>

=item * L<Text::TabularDisplay>

=item * L<Text::UnicodeBox::Table>

=back

Support matrix for each backend:

 +-------------------------------+-------+--------------------------------------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+
 | backend                       | align | align_note                                                   | backend_opts | backend_opts_note                                                                              | caption | header_row | rows | separate_rows |
 +-------------------------------+-------+--------------------------------------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+
 | Term::Table                   | 0     |                                                              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Term::TablePrint              | 0     |                                                              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::ANSITable               | 1     |                                                              |              |                                                                                                | 0       | 1          | 1    | 1             |
 | Text::ASCIITable              | 1     |                                                              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::FormatTable             | 1     | c(enter) alignment is not supported, will fallback to l(eft) |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::MarkdownTable           | 0     |                                                              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::Table                   | 1     |                                                              |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::Table::ASV              | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::CSV              | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::HTML             | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 1       | 1          | 1    | 0             |
 | Text::Table::HTML::DataTables | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 1       | 1          | 1    | 0             |
 | Text::Table::LTSV             | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 0          | 1    | 0             |
 | Text::Table::Manifold         | 1     |                                                              |              |                                                                                                | 0       | 1          | 1    | 0             |
 | Text::Table::More             | 1     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::Org              | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 1       | 1          | 1    | 1             |
 | Text::Table::Paragraph        | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::Sprintf          | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TSV              | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 0          | 1    | 0             |
 | Text::Table::TickitWidget     | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::Table::Tiny             | 1     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyBorderStyle  | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyColor        | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyColorWide    | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::TinyWide         | 0     | TODO, backend does not support yet, parameter already passed | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 1             |
 | Text::Table::XLSX             | 0     |                                                              | 1            | Backend-specific options (backend_opts) will be passed to table() or generate_table() directly | 0       | 1          | 1    | 0             |
 | Text::TabularDisplay          | 0     |                                                              |              |                                                                                                | 0       | 0          | 1    | 0             |
 | Text::UnicodeBox::Table       | 0     | TODO: backend supports left/right                            |              |                                                                                                | 0       | 1          | 1    | 0             |
 +-------------------------------+-------+--------------------------------------------------------------+--------------+------------------------------------------------------------------------------------------------+---------+------------+------+---------------+

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

=item * align

Optional. Array of Str or Str.

This takes an array ref with one entry per column, to specify the alignment of
that column. Legal values are 'l', 'c', and 'r'. You can also specify a single
alignment for all columns.

Note that some backends like L<Text::ANSITable> and L<Text::Table::More> support
per-row or per-cell or even conditional alignment. Some backends like
L<Text::ASCIITable> and L<Text::Table> can also align beyond just l(eft),
c(enter), r(right), e.g. C<justify> or align on a decimal point. To do more
fine-grained alignment setting, you can use the C<backend_opts> parameter.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

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
