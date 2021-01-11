package WHO::GrowthReference::GenTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-10'; # DATE
our $DIST = 'WHO-GrowthReference-GenTable'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(add_who_growth_reference_fields_to_table);

our %SPEC;

$SPEC{add_who_growth_reference_fields_to_table} = {
    v => 1.1,
    summary => 'Add WHO reference fields to table',
    description => <<'_',

You supply a CSV/TSV containing these fields: `date` (or `age`), `height`, and
`weight`. And these additional fields will be added:

    height_potential
    height_zscore
    height_z-3
    height_z-2
    height_z-1
    height_z0
    height_z+1
    height_z+2
    height_z+3
    weight_zscore
    weight_z-3
    weight_z-2
    weight_z-1
    weight_z0
    weight_z+1
    weight_z+2
    weight_z+3
    bmi_zscore
    bmi_z-2
    bmi_z-1
    bmi_z0
    bmi_z+1
    bmi_z+2

_
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
    },
};
sub add_who_growth_reference_fields_to_table {
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

    my @orig_fields = sort keys %{ $aoh->[0] };

    my $i = -1;
  ADD_FIELDS: {
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
            #use DD; dd $res->[2];
            $row->{age_ym} = $res->[2]{age};
            if (defined $height_key) {
                $row->{'height_potential'} = $res->[2]{height_potential};
                $row->{'height_zscore'} = $res->[2]{height_zscore};
                $row->{'height_z-3'} = $res->[2]{'height_Z-3'};
                $row->{'height_z-2'} = $res->[2]{'height_Z-2'};
                $row->{'height_z-1'} = $res->[2]{'height_Z-1'};
                $row->{'height_z0'}  = $res->[2]{'height_Z0'};
                $row->{'height_z+1'} = $res->[2]{'height_Z+1'};
                $row->{'height_z+2'} = $res->[2]{'height_Z+2'};
                $row->{'height_z+3'} = $res->[2]{'height_Z+3'};
            }
            if (defined $weight_key) {
                $row->{'weight_zscore'} = $res->[2]{weight_zscore};
                $row->{'weight_z-3'} = $res->[2]{'weight_Z-3'};
                $row->{'weight_z-2'} = $res->[2]{'weight_Z-2'};
                $row->{'weight_z-1'} = $res->[2]{'weight_Z-1'};
                $row->{'weight_z0'}  = $res->[2]{'weight_Z0'};
                $row->{'weight_z+1'} = $res->[2]{'weight_Z+1'};
                $row->{'weight_z+2'} = $res->[2]{'weight_Z+2'};
                $row->{'weight_z+3'} = $res->[2]{'weight_Z+3'};
            }
            if (defined $height_key && defined $weight_key) {
                if ($row->{$weight_key} && $row->{$height_key}) {
                    $row->{bmi} = $row->{$weight_key} / ($row->{$height_key}/100)**2;
                }
                $row->{'bmi_zscore'} = $res->[2]{bmi_zscore};
                $row->{'bmi_z-2'} = $res->[2]{'bmi_Z-2'};
                $row->{'bmi_z-1'} = $res->[2]{'bmi_Z-1'};
                $row->{'bmi_z0'}  = $res->[2]{'bmi_Z0'};
                $row->{'bmi_z+1'} = $res->[2]{'bmi_Z+1'};
                $row->{'bmi_z+2'} = $res->[2]{'bmi_Z+2'};
            }
        }
    } # ADD_FIELDS

    [200, "OK", $aoh, {'table.fields'=>[$date_key, $age_key, $height_key, $weight_key, @orig_fields]}];
}

1;
# ABSTRACT: Add WHO reference fields to table

__END__

=pod

=encoding UTF-8

=head1 NAME

WHO::GrowthReference::GenTable - Add WHO reference fields to table

=head1 VERSION

This document describes version 0.001 of WHO::GrowthReference::GenTable (from Perl distribution WHO-GrowthReference-GenTable), released on 2021-01-10.

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

 % add-who-growth-reference-fields-to-table M 2014-04-15 data.csv

=head1 DESCRIPTION

=head1 KEYWORDS

growth standards, growth reference

=head1 FUNCTIONS


=head2 add_who_growth_reference_fields_to_table

Usage:

 add_who_growth_reference_fields_to_table(%args) -> [status, msg, payload, meta]

Add WHO reference fields to table.

You supply a CSV/TSV containing these fields: C<date> (or C<age>), C<height>, and
C<weight>. And these additional fields will be added:

 height_potential
 height_zscore
 height_z-3
 height_z-2
 height_z-1
 height_z0
 height_z+1
 height_z+2
 height_z+3
 weight_zscore
 weight_z-3
 weight_z-2
 weight_z-1
 weight_z0
 weight_z+1
 weight_z+2
 weight_z+3
 bmi_zscore
 bmi_z-2
 bmi_z-1
 bmi_z0
 bmi_z+1
 bmi_z+2

This function is not exported by default, but exportable.

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

Please visit the project's homepage at L<https://metacpan.org/release/WHO-GrowthReference-GenTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WHO-GrowthReference-GenTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WHO-GrowthReference-GenTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WHO::GrowthReference::Table>

L<WHO::GrowthReference::GenChart>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
