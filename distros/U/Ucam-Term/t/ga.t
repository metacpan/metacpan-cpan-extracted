#!/usr/bin/perl -w

use strict;

use Test::More tests => 51;
#use Test::More 'no_plan';
use Test::Exception;

my $term;

# Basic 'can we use it' test
BEGIN { use_ok('Ucam::Term') };

# Check General Admission for 2025 becasue prior to Grace 2 of 
# 5 February 2014 the S&A algorythm didn't produce the same dates
# as the table on S&O
$term =  Ucam::Term->new('e',2025);

is ($term->general_admission->start->iso8601, 
    '2025-07-02T00:00:00',
    'Unexpected data for 2015 START via table');

is ($term->general_admission->end->iso8601,
    '2025-07-06T00:00:00',
    'Unexpected data for 2015 END via table');

is ($term->general_admission_alg->start->iso8601, 
    '2025-07-02T00:00:00',
    'Unexpected data for 2015 START via algorythm');

is ($term->general_admission_alg->end->iso8601,
    '2025-07-06T00:00:00',
    'Unexpected data for 2015 END via algorythm');

# Currently have data for 23 years
foreach my $year (Ucam::Term->available_years) {

    $term = Ucam::Term->new('e',$year);
    next unless $term->dates;

    cmp_ok ($term->general_admission->start->iso8601,
	    'eq',
            $term->general_admission_alg->start->iso8601,
            "Table/algorythm mismatch for $year START");

    cmp_ok ($term->general_admission->end->iso8601,
	    'eq',
            $term->general_admission_alg->end->iso8601,
            "Table/algorythm mismatch for $year END");

}
