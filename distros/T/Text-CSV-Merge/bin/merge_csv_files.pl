#! /usr/bin/env perl -w
# PODNAME: merge_csv_files.pl
# ABSTRACT: Command line client to Text::CSV::Merge

use Modern::Perl;
use Getopt::Long;
use Text::CSV::Merge;

## Setup Options
my $base_file;
my $merge_file;
my $output_file = 'merge.csv';
my $search_field;
my $first_row_is_headers = 1;
my @columns;

GetOptions(
    "base=s"    => \$base_file,  # string
    "merge=s"     => \$merge_file, # string
    "output=s"  => \$output_file, # string
    "columns=s" => \@columns, # list
    "search=s"  => \$search_field, # string
    "first-row-is-headers" => \$first_row_is_headers, # flag
) or die("Error in command line arguments\r\n");

# set column names for the hash; we'll use @columns more, later.
@columns = split(/,/, join(',', @columns));

## Merge rows!
my $merger = Text::CSV::Merge->new({
    base    => $base_file,
    merge   => $merge_file,
    output  => $output_file,
    columns => \@columns,
    search  => $search_field,
    first_row_is_headers => $first_row_is_headers
});

$merger->merge();

# Ensure clean exit, since some shells don't save the command in history
# without it.
exit 0;

__END__

=pod

=head1 NAME

merge_csv_files.pl - Command line client to Text::CSV::Merge

=head1 VERSION

version 0.05

=head1 Synopsis

    merge_csv_files.pl \
        --base=merge_into.csv \
        --merge=merge_from.csv \ 
        --columns=EMAIL,FNAME,LNAME,LOCATION,JAN,FEB,MAR,APR,MAY,JUN \
        --output=merge.csv \
        --search=EMAIL \
        --first-row-is-headers

=head1 Description

You have two CSV files with mostly the same column names. But, the 'base' CSV files has gaps in its data, i.e. some cells are empty. Another CSV has data, but its too laborious to comb through it by hand. Use this CLI to fill in the gaps.

=head1 Options

=head2 Required Options

=head3 base

The CSV file into which you want to merge data.

=head3 merge

The CSV file with which you want to fill in data gaps in C<base>. 

=head3 columns

A quoted, anonymous list of column names. Non-ASCII column names are as yet untested.

=head3 search

The column name by which you want to match up rows in C<base> and C<merge>.

=head2 Optional Options

=head3 output

Name of a file to which you want to direct the refined data. Default is C<merged.csv>.

=head3 first-row-is-headers

Specify 1 or 0 (or do not specify at all) to designate the first row of both CSV files as column headings.

Default is 1, or TRUE (Remember, Perl has no built-in Boolean).

=head1 AUTHOR

Michael Gatto <mgatto@lisantra.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Gatto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
