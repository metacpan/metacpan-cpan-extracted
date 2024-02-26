package Text::Chart;

use 5.010001;
use strict;
use utf8;
use warnings;
use Log::ger;

use Exporter qw(import);
use List::MoreUtils qw(minmax);
use Scalar::Util qw(looks_like_number);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Text-Chart'; # DIST
our $VERSION = '0.042'; # VERSION

our @EXPORT_OK = qw(gen_text_chart);

our %SPEC;

our @CHART_TYPES = (
    'raw',
    'bar',
    #'column',
    'sparkline',
    #hsparkline
    #line
    #pie
    #area (see Google Charts API)
    #tree map (see Google Charts API)
);

my @sparkline_chars  = split //, '▁▂▃▄▅▆▇█';
my @hsparkline_chars = split //, '▏▎▍▌▋▊▉█';

sub _get_column_data {
    my ($tbl, $col) = @_;
    my $res = $tbl->select_as_aoaos([$col]);
    my $coldata = [];
    for (@{ $res->{data} }) {
        push @$coldata, $_->[0];
    }
    $coldata;
}

sub _find_first_numcol {
    my $tbl = shift;

  COL:
    for my $col (@{ $tbl->cols_by_idx }) {
        my $coldata = _get_column_data($tbl, $col);
        my $is_numeric = 1;
        for (1..10) {
            last if $_ > @$coldata;
            if (!looks_like_number($coldata->[$_-1])) {
                $is_numeric = 0;
                next COL;
            }
        }
        return $col if $is_numeric;
    }
    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
}

sub _find_first_nonnumcol {
    my $tbl = shift;

  COL:
    for my $col (@{ $tbl->cols_by_idx }) {
        my $coldata = _get_column_data($tbl, $col);
        my $is_nonnum = 1;
        for (1..10) {
            last if $_ > @$coldata;
            my $data = $coldata->[$_-1];
            if (defined($data) && !looks_like_number($data)) {
                $is_nonnum = 0;
                next COL;
            }
        }
        return $col if $is_nonnum;
    }
    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
}

$SPEC{gen_text_chart} = {
    v => 1.1,
    summary => "Generate text-based chart",
    args => {
        data => {
            summary => '(Table) data to chart',
            schema => ['any*', of => [
                ['array*' => of => 'num*'],
                ['array*' => of => 'array*'],
                ['array*' => of => 'hash*'],
            ]],
            req => 1,
            description => <<'MARKDOWN',

Either in the form of array of numbers, example:

    [1366,1248,319,252]

or an array of arrays (there must be at least one number columns), example:

    [["China",1366],["India",1248],["United Status",319], ["Indonesia",252]]

or an array of hashes (there must be at least one key which consistently contain
numbers), example:

    [{country=>"China"        , population=>1366},
     {country=>"India"        , population=>1248},
     {country=>"United Status", population=> 319},
     {country=>"Indonesia"    , population=> 252}]

All data needs to be in table form (where there are notions of rows and
columns/fields). Array data is assumed to be a single-column table with the
column named `data`. Array of arrays will have columns named `column0`,
`column1` and so on. Array of hashes will have columns named according to the
hash keys.

MARKDOWN
        },
        spec => {
            summary => 'Table specification, according to TableDef',
            schema => 'hash*', # XXX TableDef
        },
        type => {
            summary => 'Chart type',
            schema => ['str*', in => \@CHART_TYPES],
            req => 1,
        },
        label_column => {
            summary => 'Which column(s) contain data labels',
            schema => 'str_or_aos1::arrayified',
            description => <<'MARKDOWN',

If not specified, the first non-numeric column will be selected.

The number of label columns must match that of data columns.

MARKDOWN
            'x.chart_types' => ['bar'],
        },
        data_column => {
            summary => 'Which column(s) contain data to plot',
            description => <<'MARKDOWN',

Multiple data columns are supported.

MARKDOWN
            schema => 'str_or_aos1::arrayified',
        },
        chart_height => {
            schema => 'float*',
            'x.chart_types' => ['sparkline'],
        },
        chart_width => {
            schema => 'float*',
            'x.chart_types' => ['bar'],
        },
        show_data_label => {
            schema => 'bool*',
            'x.chart_types' => ['bar'],
        },
        show_data_value => {
            schema => 'bool*',
            'x.chart_types' => ['bar'],
        },
        # XXX data_formats
        # XXX show_x_axis
        # XXX show_y_axis
        # XXX data_scale
        # XXX log_scale
    },
    result_naked => 1,
    result => {
        schema => 'str*',
    },
};
sub gen_text_chart {
    require Data::TableData::Object;

    my %args = @_;
    #use DD; dd \%args;

    # XXX schema
    $args{data} or die "Please specify 'data'";
    my $tbl = Data::TableData::Object->new($args{data}, $args{spec});

    my @data_columns;
    {
        my $dc = $args{data_column};
        if (defined $dc) {
            @data_columns = ref($dc) eq 'ARRAY' ? @$dc : ($dc);
        } else {
            my $col = _find_first_numcol($tbl);
            die "There is no numeric column for data" unless defined $col;
            @data_columns = ($col);
        }
    }

    my @label_columns;
    {
        my $lc = $args{label_column};
        if (defined $lc) {
            @label_columns = ref($lc) eq 'ARRAY' ? @$lc : ($lc);
        } else {
            my $col = _find_first_nonnumcol($tbl);
            die "There is no non-numeric column for data" unless defined $col;
            @label_columns = ($col);
        }
        if (@label_columns != @data_columns) {
            die "Number of data columns (".scalar(@data_columns).") does not match number of label columns (".scalar(@label_columns).")";
        }
    }

    my $buf = "";

    my $type = $args{type} or die "Please specify 'type'";
    my $chart_height = $args{chart_height};
    my $chart_width = $args{chart_width};

    if ($type eq 'raw') {

        my @resrows;
        for my $rowidx (0 .. $tbl->row_count-1) {
            my $resrow = {};
            my $origrow = $tbl->row_as_hos($rowidx);
            for my $i (0 .. @data_columns-1) {
                $resrow->{"data$i"} = $origrow->{$data_columns[$i]};
                $resrow->{"label$i"} = $origrow->{$label_columns[$i]};
            }
            push @resrows, $resrow;
        }
        require JSON::MaybeXS;
        $buf = JSON::MaybeXS::encode_json([200, "OK", \@resrows]);

    } elsif ($type eq 'bar') {
        $chart_width //= 75;

        # calculate maximum label width
        my $max_label_width = 0;
        for my $col (@label_columns) {
            my $coldata = [map {$_//''} @{ _get_column_data($tbl, $col) }];
            for my $data (@$coldata) {
                my $len = length($data);
                $max_label_width = $len if $max_label_width < $len;
            }
        }

        # get maximum value & maximum width for each data column
        my @max; # index: colnum
        my $max_value_width = 0;
        for my $colidx (0 .. @data_columns-1) {
            my $coldata = [map {$_//0} @{ _get_column_data($tbl, $data_columns[$colidx]) }];
            for my $data (@$coldata) {
                $max[$colidx] = $data if !defined($max[$colidx]) || $max[$colidx] < $data;
                my $len = length($data);
                $max_value_width = $len if $max_value_width < $len;
            }
        }

        my $bar_width = $chart_width
            - ($args{show_data_label} ? $max_label_width+1 : 0) # "label|"
            - ($args{show_data_value} ? $max_value_width+2 : 0) # "(val)"
            ;
        $bar_width = 1 if $bar_width < 1;

        # which characters to use to draw:
        my @chars = ('*','=', 'o', 'X', '.', '+', 'x');

        # draw
        for my $rowidx (0 .. $tbl->row_count-1) {
            my $row = $tbl->row_as_hos($rowidx);
            for my $colidx (0 .. @data_columns-1) {
                my $char = $chars[ $colidx % @chars ];
                $buf .= sprintf("%-${max_label_width}s|", $row->{$label_columns[$colidx]}) if $args{show_data_label};

                my $width;
                my $val = $row->{$data_columns[$colidx]};
                if (!$max[$colidx]) {
                    $width = 0;
                } else {
                    $width = int($bar_width * ($val / $max[$colidx]));
                }
                $buf .= sprintf("%-${bar_width}s", $char x $width);

                $buf .= sprintf("(%${max_value_width}s)", $val) if $args{show_data_value};

                $buf .= "\n";
            }
            $buf .= "\n" if @data_columns > 1;
        } # for row

    } elsif ($type eq 'sparkline') {
        $chart_height //= 1;
        for my $col (@data_columns) {
            my $coldata = [map {$_//0} @{ _get_column_data($tbl, $col) }];
            my @dbuf = ( (" " x @$coldata) . "\n" ) x $chart_height;
            my ($min, $max) = minmax(@$coldata);
            my @heights;
            for my $d (@$coldata) {
                my $h;
                if ($max != $min) {
                    $h = ($d-$min)/($max-$min) * $chart_height;
                } else {
                    $h = 0;
                }
                push @heights, $h;
            }
            for my $line (1..$chart_height) {
                my $h1 = $chart_height-$line;
                for my $i (0..@$coldata-1) {
                    my $j; # which sparkline character to use
                    my $d = $coldata->[$i];
                    my $height = $heights[$i];
                    if ($height > $h1+1) {
                        $j = @sparkline_chars-1; # full
                    } elsif ($height > $h1) {
                        $j = sprintf("%.0f", ($height-$h1)*(@sparkline_chars-1));
                    } else {
                        # empty
                        next;
                    }
                    substr($dbuf[$line-1], $i, 1) = $sparkline_chars[$j];
                }
            }
            $buf .= join "", @dbuf;
        }
    } else {
        die "Unknown chart type '$type'";
    }

    $buf;
}

1;
# ABSTRACT: Generate text-based chart

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Chart - Generate text-based chart

=head1 VERSION

This document describes version 0.042 of Text::Chart (from Perl distribution Text-Chart), released on 2024-02-06.

=head1 SYNOPSIS

 use Text::Chart qw(gen_text_chart);

B<Bar chart:>

 my $res = gen_text_chart(
     data => [1, 5, 3, 9, 2],
     type => 'bar',
 );

will produce this:

 *
 *****
 ***
 *********
 **

B<Adding data labels and showing data values:>

 my $res = gen_text_chart(
     data => [["Andi",1], ["Budi",5], ["Cinta",3], ["Dewi",9], ["Edi",2]],
     type => 'bar',
     show_data_label => 1,
     show_data_value => 1,
 );

Result:

 Andi |*         (1)
 Budi |*****     (5)
 Cinta|***       (3)
 Dewi |********* (9)
 Edi  |**        (2)

C<Column chart:>

 my $res = gen_text_chart(
     data => [["Andi",1], ["Budi",5], ["Cinta",3], ["Dewi",9], ["Edi",2]],
     type => 'column',
     show_data_label => 1,
 );

Result:

                     *
                     *
                     *
                     *
        *            *
        *            *
  *     *      *     *
  *     *      *     *     *
  *     *      *     *     *
 Andi  Budi  Cinta  Dewi  Edi

B<Sparkline chart:>

Via L<tchart> (from L<App::tchart>) CLI:

 % tchart -d sales -t sparkline < celine-dion-album-sales.json
 ▂▂▅██▄▄▂▁▂▁

B<Horizontal sparkline chart:>

 XXX

C<Plotting multiple data columns:>

 XXX

=head1 DESCRIPTION

B<THIS IS AN EARLY RELEASE, MANY FEATURES ARE NOT YET IMPLEMENTED.>

This module lets you generate text-based charts.

=head1 FUNCTIONS


=head2 gen_text_chart

Usage:

 gen_text_chart(%args) -> str

Generate text-based chart.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chart_height> => I<float>

(No description)

=item * B<chart_width> => I<float>

(No description)

=item * B<data>* => I<array[num]|array[array]|array[hash]>

(Table) data to chart.

Either in the form of array of numbers, example:

 [1366,1248,319,252]

or an array of arrays (there must be at least one number columns), example:

 [["China",1366],["India",1248],["United Status",319], ["Indonesia",252]]

or an array of hashes (there must be at least one key which consistently contain
numbers), example:

 [{country=>"China"        , population=>1366},
  {country=>"India"        , population=>1248},
  {country=>"United Status", population=> 319},
  {country=>"Indonesia"    , population=> 252}]

All data needs to be in table form (where there are notions of rows and
columns/fields). Array data is assumed to be a single-column table with the
column named C<data>. Array of arrays will have columns named C<column0>,
C<column1> and so on. Array of hashes will have columns named according to the
hash keys.

=item * B<data_column> => I<str_or_aos1::arrayified>

Which column(s) contain data to plot.

Multiple data columns are supported.

=item * B<label_column> => I<str_or_aos1::arrayified>

Which column(s) contain data labels.

If not specified, the first non-numeric column will be selected.

The number of label columns must match that of data columns.

=item * B<show_data_label> => I<bool>

(No description)

=item * B<show_data_value> => I<bool>

(No description)

=item * B<spec> => I<hash>

Table specification, according to TableDef.

=item * B<type>* => I<str>

Chart type.


=back

Return value:  (str)

=head1 FAQ

=head2 Why am I getting 'Wide character in print/say' warning?

You are probably printing Unicode characters to STDOUT without doing something
like this beforehand:

 binmode(STDOUT, ":utf8");

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Chart>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Chart>.

=head1 SEE ALSO

L<Text::Graph>, a mature CPAN module for doing text-based graphs. Before writing
Text::Chart I used this module for a while, but ran into the problem of weird
generated graphs. In addition, I don't like the way Text::Graph draws things,
e.g. a data value of 1 is drawn as zero-width bar, or the label separator C<:>
is always drawn. So I decided to write an alternative charting module instead.
Compared to Text::Graph, here are the things I want to add or do differently as
well: functional (non-OO) interface, colors, Unicode, resampling, more chart
types like sparkline, animation and some interactivity (perhaps).

L<App::tchart>, a CLI for Text::Chart.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2024, 2017, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Chart>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
