package Text::Chart;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;

use List::MoreUtils qw(minmax);
use Scalar::Util qw(looks_like_number);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_text_chart);

our %SPEC;

our @CHART_TYPES = (
    #'bar',
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

sub _find_first_numcol {
    my $tbl = shift;

  COL:
    for my $col (@{ $tbl->columns }) {
        my $coldata = $tbl->column_data($col);
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
    return undef;
}

sub _find_first_nonnumcol {
    my $tbl = shift;

  COL:
    for my $col (@{ $tbl->columns }) {
        my $coldata = $tbl->column_data($col);
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
    return undef;
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
            pos => 1,
            description => <<'_',

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

_
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
            summary => 'Which column contains data labels',
            schema => 'str*',
            description => <<'_',

If not specified, the first non-numeric column will be selected.

_
        },
        data_column => {
            summary => 'Which column(s) contain data to plot',
            description => <<'_',

Multiple data columns are supported.

_
            schema => ['any*' => of => [
                'str*',
                ['array*' => of => 'str*'],
            ]],
        },
        chart_height => {
            schema => 'float*',
        },
        chart_width => {
            schema => 'float*',
        },
        # XXX show_data_label
        # XXX show_data_value
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
    require TableData::Object;

    my %args = @_;
    #use DD; dd \%args;

    # XXX schema
    $args{data} or die "Please specify 'data'";
    my $tbl = TableData::Object->new($args{data}, $args{spec});

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

    my $label_column = $args{label_column};
    if (!defined($label_column)) {
        my $col = _find_first_nonnumcol($tbl);
        die "There is no non-numeric column for label"
            if $args{show_data_label} && !defined($col);
        $label_column = $col;
    }

    my $buf = "";

    my $type = $args{type} or die "Please specify 'type'";
    my $chart_height = $args{chart_height};
    if ($type eq 'sparkline') {
        $chart_height //= 1;
        for my $col (@data_columns) {
            my $coldata = [map {$_//0} @{ $tbl->column_data($col) }];
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

This document describes version 0.02 of Text::Chart (from Perl distribution Text-Chart), released on 2015-01-03.

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

C<Sparkline chart:>

 my $res = gen_text_chart(
     data => [["Andi",1], ["Budi",5], ["Cinta",3], ["Dewi",9], ["Edi",2]],
     type => 'column',
     show_data_label => 1,
 );

 my $res = gen_text_chart(
     data => [1.5, 0.5, 3.5, 2.5, 5.5, 4.5, 7.5, 6.5],
     type => 'sparkline',
 );

Result:

 XXX

C<Plotting multiple data columns:>

 XXX

=head1 DESCRIPTION

B<THIS IS AN EARLY RELEASE, MANY FEATURES ARE NOT YET IMPLEMENTED.> Currently
only sparkline chart is implemented. Showing data labels and data values are not
yet implemented.

This module lets you generate text-based charts.

=head1 FUNCTIONS


=head2 gen_text_chart(%args) -> str

Generate text-based chart.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chart_height> => I<float>

=item * B<chart_width> => I<float>

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

=item * B<data_column> => I<str|array[str]>

Which column(s) contain data to plot.

Multiple data columns are supported.

=item * B<label_column> => I<str>

Which column contains data labels.

If not specified, the first non-numeric column will be selected.

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

=head1 SEE ALSO

L<Text::Graph>, a mature CPAN module for doing text-based graphs. Before writing
Text::Chart I used this module for a while, but ran into the problem of weird
generated graphs. In addition, I don't like the way Text::Graph draws things,
e.g. a data value of 1 is drawn as zero-width bar, or the label separator C<:>
is always drawn. So I decided to write an alternative charting module instead.
Compared to Text::Graph, here are the things I want to add or do differently as
well: functional (non-OO) interface, colors, Unicode, resampling, more chart
types like sparkline, animation and some interactivity (perhaps).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Chart>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Text-Chart>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Chart>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
