#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Text::Levenshtein::Edlib', ':all') };


my $fail = 0;
foreach my $constname (qw(
	EDLIB_CIGAR_EXTENDED EDLIB_CIGAR_STANDARD EDLIB_EDOP_DELETE
	EDLIB_EDOP_INSERT EDLIB_EDOP_MATCH EDLIB_EDOP_MISMATCH EDLIB_MODE_HW
	EDLIB_MODE_NW EDLIB_MODE_SHW EDLIB_STATUS_ERROR EDLIB_STATUS_OK
	EDLIB_TASK_DISTANCE EDLIB_TASK_LOC EDLIB_TASK_PATH)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Text::Levenshtein::Edlib macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );

my $r = distance 'kitten', 'sitting';
is $r, 3, 'distance';
$r = distance 'kitten', 'sitting', 2;
ok !defined $r, 'distance w/ max_distance';

$r = align 'kitten', 'sitting';
is $r->{editDistance}, 3, 'align->{editDistance}';
is $r->{alphabetLength}, 7, 'align->{alphabetLength}';

is_deeply $r->{endLocations}, [6], 'align->{endLocations}';
is_deeply $r->{startLocations}, [0], 'align->{startLocations}';
is_deeply $r->{alignment}, [3, 0, 0, 0, 3, 0, 2], 'align->{alignment}';

my $cigar;
$cigar = to_cigar $r->{alignment};
is $cigar, '6M1D', 'to_cigar';
$cigar = to_cigar $r->{alignment}, EDLIB_CIGAR_EXTENDED;
is $cigar, '1X3=1X1=1D', 'to_cigar (extended)';
