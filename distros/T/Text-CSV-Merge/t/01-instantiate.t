#!/usr/bin/env perl -T

use Test::More tests => 2;
use Text::CSV::Merge;

BEGIN {
}

# create an object
my $merge = Text::CSV::Merge->new({
    base    => 't/merge_into.csv',
    merge   => 't/merge_from.csv',
    output  => 't/merge.csv',
    columns => [qw/EMAIL FNAME LNAME LOCATION JAN FEB MAR APR MAY JUN/],
    search  => 'EMAIL',
    first_row_is_headers => 1
});

ok( defined $merge );                # check that we got something
ok( $merge->isa('Text::CSV::Merge') );     # and it's the right class
