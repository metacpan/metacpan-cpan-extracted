package WHO::GrowthReference::GenChart;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-10'; # DATE
our $DIST = 'WHO-GrowthReference-GenChart'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_who_growth_chart_from_tsv);

our %SPEC;

$SPEC{gen_who_growth_chart_from_table} = {
    v => 1.1,
    summary => 'Create WHO growth chart ()',
    args => {
        gender => {
            schema => ['str*', in=>['M','F']],
            req => 1,
            pos => 0,
        },
        name => {
            schema => 'str*',
        },
        dob => {
            schema => 'date*',
            req => 1,
            pos => 1,
        },
        table => {
            summary => 'Table of growth, must be in CSV/TSV format, containing at least age/date and weight/height columns',
            description => <<'_',

TSV/CSV must have header line.

Date must be string in YYYY-MM-DD format. Age must be float in years. Weight
must be float in kg. Height must be float in cm.

Example:

    date,height,weight
    2020-11-01,113.5,17.8
    2020-11-15,113.5,17.9
    2020-12-01,114,17.9
    2020-12-15,114,17.9
    2021-01-01,115,18.1
    2021-01-15,115.5,18.3
    2021-02-01,116,18.4

_
            schema => 'str*',
            req => 1,
            pos => 2,
            cmdline_src => 'stdin_or_file',
        },
        which => {
            summary => 'Specify which chart to generate',
            schema => ['str*', in=>['height', 'weight', 'bmi']],
            req => 1,
        },
    },
};
sub gen_who_growth_chart_from_table {
    require Chart::Gnuplot;
    require File::Temp;
    require List::Util;
    require Time::Local;
    require WHO::GrowthReference::Table;

    my %args = @_;
    my $gender = $args{gender};
    my $dob    = $args{dob};
    my $which  = $args{which};

    my $aoh;
    my ($age_key, $date_key, $height_key, $weight_key);

  GET_INPUT_TABLE_DATA: {
        my $table = $args{table};
        require Text::CSV_XS;
        my %csv_args = (in => \$table, headers => 'auto');
        if ($table =~ /\t/) {
            # assume TSV if input contains Tab character
            $csv_args{sep_char} = "\t";
            $csv_args{quote_char} = undef;
            $csv_args{escape_char} = undef;
        }
        $aoh = Text::CSV_XS::csv(%csv_args);
        return [400, "Table does not contain any data rows"] unless @$aoh;
        my @keys = sort keys %{ $aoh->[0] };
        $age_key    = List::Util::first(sub { /age/i }, @keys);
        $date_key   = List::Util::first(sub { /date|time/i }, @keys);
        defined($age_key) || defined($date_key) or return [400, "Table does not contain 'age' nor 'date/time' field"];
        $height_key = List::Util::first(sub { /height/i }, @keys);
        if ($which eq 'height' || $which eq 'bmi') {
            defined $height_key or return [400, "Table does not contain 'height' field"];
        }
        $weight_key = List::Util::first(sub { /weight/i }, @keys);
        if ($which eq 'weight' || $which eq 'bmi') {
            defined $weight_key or return [400, "Table does not contain 'weight' field"];
        }
    }

    my ($tempfh, $tempfilename) = File::Temp::tempfile();
    $tempfilename .= ".png";

    my $chart = Chart::Gnuplot->new(
        output   => $tempfilename,
        title    => "WHO $which chart".($args{name} ? " for $args{name}" : ""),
        xlabel   => 'age (years)',
        ylabel   => ($which eq 'height' ? 'height (cm)' : $which eq 'weight' ? 'weight (kg)' : 'BMI'),
        #xtics    => {labelfmt=>'%H:%M'},

        #yrange   => [0, List::Util::max($max_urate_scale, $max_ivol_scale)],
        #y2range  => [0, List::Util::max($max_urate_scale, $max_ivol_scale)],
    );

    my (@age,
        @height, @height_zm3, @height_zm2, @height_zm1, @height_z0, @height_z1, @height_z2, @height_z3,
        @weight, @weight_zm3, @weight_zm2, @weight_zm1, @weight_z0, @weight_z1, @weight_z2, @weight_z3,
        @bmi   ,            , @bmi_zm2   , @bmi_zm1   , @bmi_z0   , @bmi_z1   , @bmi_z2   ,
    );
    my $i = -1;
  SET_DATA_SETS: {
        for my $row (@$aoh) {
            $i++;
            my $time;
            if (defined $date_key) {
                my $date = $row->{$date_key};
                unless ($date =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)/) {
                    return [400, "Table row[$i]: date is not in YYYY-MM-DD format: '$date'"];
                }
                $time = Time::Local::timelocal(0, 0, 0, $3, $2-1, $1);
            }
            my $res = WHO::GrowthReference::Table::get_who_growth_reference(
                gender => $gender,
                defined($date_key) ? (dob => $dob, now => $time) : (age => 365.25*86400*$row->{$age_key}),
                defined($height_key) ? (height => $row->{$height_key}) : (),
                defined($weight_key) ? (weight => $row->{$weight_key}) : (),
            );
            return [400, "Table row[$i]: Cannot get WHO growth reference data: $res->[0] - $res->[1]"]
                unless $res->[0] == 200;
            $res->[2]{age} =~ /^(\d+(?:\.\d+)?)/ or die; push @age, $1/12;
            if (defined $height_key) {
                push @height, $row->{$height_key};
                push @height_z0 , $res->[2]{height_Z0};
                push @height_zm1, $res->[2]{'height_Z-1'};
                push @height_z1 , $res->[2]{'height_Z+1'};
                push @height_zm2, $res->[2]{'height_Z-2'};
                push @height_z2 , $res->[2]{'height_Z+2'};
                push @height_zm3, $res->[2]{'height_Z-3'};
                push @height_z3 , $res->[2]{'height_Z+3'};
            }
            if (defined $weight_key) {
                push @weight, $row->{$weight_key};
                push @weight_z0 , $res->[2]{weight_Z0};
                push @weight_zm1, $res->[2]{'weight_Z-1'};
                push @weight_z1 , $res->[2]{'weight_Z+1'};
                push @weight_zm2, $res->[2]{'weight_Z-2'};
                push @weight_z2 , $res->[2]{'weight_Z+2'};
                push @weight_zm3, $res->[2]{'weight_Z-3'};
                push @weight_z3 , $res->[2]{'weight_Z+3'};
            }
            if (defined $height_key && defined $weight_key) {
                if ($row->{$weight_key} && $row->{$height_key}) {
                    push @bmi, $row->{$weight_key} / ($row->{$height_key}/100)**2;
                } else {
                    push @bmi, undef;
                }
                push @bmi_z0 , $res->[2]{bmi_Z0};
                push @bmi_zm1, $res->[2]{'bmi_Z-1'};
                push @bmi_z1 , $res->[2]{'bmi_Z+1'};
                push @bmi_zm2, $res->[2]{'bmi_Z-2'};
                push @bmi_z2 , $res->[2]{'bmi_Z+2'};
            }
        }
    } # SET_DATA_SETS

    # PLOT
    my @datasets;

    if ($which eq 'height') {
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height,
            title => 'height',
            color => 'blue',
            style => 'linespoints',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_z0,
            title => 'height z0',
            color => 'green',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_z1,
            title => 'height z+1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_zm1,
            title => 'height z-1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_z2,
            title => 'height z+2',
            color => 'red',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_zm2,
            title => 'height z-2',
            color => 'red',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_z3,
            title => 'height z+3',
            color => 'black',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@height_zm3,
            title => 'height z-3',
            color => 'black',
            style => 'lines',
        );
    } elsif ($which eq 'weight') {
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight,
            title => 'weight',
            color => 'blue',
            style => 'linespoints',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_z0,
            title => 'weight z0',
            color => 'green',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_z1,
            title => 'weight z+1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_zm1,
            title => 'weight z-1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_z2,
            title => 'weight z+2',
            color => 'red',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_zm2,
            title => 'weight z-2',
            color => 'red',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_z3,
            title => 'weight z+3',
            color => 'black',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@weight_zm3,
            title => 'weight z-3',
            color => 'black',
            style => 'lines',
        );
    } elsif ($which eq 'bmi') {
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi,
            title => 'bmi',
            color => 'blue',
            style => 'linespoints',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi_z0,
            title => 'bmi z0',
            color => 'green',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi_z1,
            title => 'bmi z+1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi_zm1,
            title => 'bmi z-1',
            color => 'orange',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi_z2,
            title => 'bmi z+2',
            color => 'red',
            style => 'lines',
        );
        push @datasets, Chart::Gnuplot::DataSet->new(
            xdata => \@age,
            ydata => \@bmi_zm2,
            title => 'bmi z-2',
            color => 'red',
            style => 'lines',
        );
    }

    $chart->plot2d(@datasets);

    require Browser::Open;
    Browser::Open::open_browser("file:$tempfilename");

    [200];
}

1;
# ABSTRACT: Create WHO growth chart ()

__END__

=pod

=encoding UTF-8

=head1 NAME

WHO::GrowthReference::GenChart - Create WHO growth chart ()

=head1 VERSION

This document describes version 0.001 of WHO::GrowthReference::GenChart (from Perl distribution WHO-GrowthReference-GenChart), released on 2021-01-10.

=head1 SYNOPSIS

In `data.csv`:

    date,height,weight
    2020-11-01,113.5,17.8
    2020-11-15,113.5,17.9
    2020-12-01,114,17.9
    2020-12-15,114,17.9
    2021-01-01,115,18.1
    2021-01-15,115.5,18.3
    2021-02-01,116,18.4

From the command-line:

 % gen-who-growth-chart-from-table M 2014-04-15 data.csv --which height

=head1 DESCRIPTION

=head1 KEYWORDS

growth standards, growth reference

=head1 FUNCTIONS


=head2 gen_who_growth_chart_from_table

Usage:

 gen_who_growth_chart_from_table(%args) -> [status, msg, payload, meta]

Create WHO growth chart ().

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dob>* => I<date>

=item * B<gender>* => I<str>

=item * B<name> => I<str>

=item * B<table>* => I<str>

Table of growth, must be in CSVE<sol>TSV format, containing at least ageE<sol>date and weightE<sol>height columns.

TSV/CSV must have header line.

Date must be string in YYYY-MM-DD format. Age must be float in years. Weight
must be float in kg. Height must be float in cm.

Example:

 date,height,weight
 2020-11-01,113.5,17.8
 2020-11-15,113.5,17.9
 2020-12-01,114,17.9
 2020-12-15,114,17.9
 2021-01-01,115,18.1
 2021-01-15,115.5,18.3
 2021-02-01,116,18.4

=item * B<which>* => I<str>

Specify which chart to generate.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WHO-GrowthReference-GenChart>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WHO-GrowthReference-GenChart>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WHO-GrowthReference-GenChart/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WHO::GrowthReference::Table>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
