#!/usr/bin/perl

# t/16-outhh.t

#
# Written by Sébastien Millet
# July 2017
#

#
# Test script for Text::AutoCSV: inputs without a header line
#

use strict;
use warnings;

use Test::More tests => 9;

#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !!( $^O =~ /mswin/i );
my $ww = ( $OS_IS_PLAIN_WINDOWS ? 'ww' : '' );

# FIXME
# If the below is zero, ignore this FIX ME entry
# If the below is non zero, it'll use some hacks to ease development
my $DEVTIME = 0;

# FIXME
# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
    use_ok('Text::AutoCSV');
}

use File::Temp qw(tmpnam);

if ($DEVTIME) {
    note("");
    note("***");
    note("***");
    note("***  !! WARNING !!");
    note("***");
    note("***  SET \$DEVTIME TO 0 BEFORE RELEASING THIS CODE TO PRODUCTION");
    note("***  RIGHT NOW, \$DEVTIME IS EQUAL TO $DEVTIME");
    note("***");
    note("***");
    note("");
}

can_ok( 'Text::AutoCSV', ('new') );

my $tmpf = &get_non_existent_temp_file_name();

note("");
note("[NO] headers in input");

my $csv = Text::AutoCSV->new(
    in_file     => "t/${ww}hh1.csv",
    out_file    => $tmpf,
    has_headers => 0
);
my $all = [ $csv->get_hr_all() ];
is_deeply(
    $all,
    [
        { '__0000__' => '1',  '__0001__' => '2' },
        { '__0000__' => '11', '__0001__' => '12' },
        { '__0000__' => '21', '__0001__' => '22' }
    ],
    "NO01: check in-memory content without header"
);
$csv->write();

my $all2 =
  [ Text::AutoCSV->new( in_file => $tmpf, has_headers => 0 )->get_hr_all() ];
is_deeply(
    $all2,
    [
        { '__0000__' => '1',  '__0001__' => '2' },
        { '__0000__' => '11', '__0001__' => '12' },
        { '__0000__' => '21', '__0001__' => '22' }
    ],
    "NO02: check in-memory content without header (after rewriting)"
);

my $csv3 = Text::AutoCSV->new(
    in_file             => "t/${ww}hh1.csv",
    out_file            => $tmpf,
    has_headers         => 0,
    out_has_headers     => 1,
    fields_column_names => [ 'C1', 'C2' ]
)->write();
my $all3 = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
is_deeply(
    $all3,
    [
        { 'C1' => '1',  'C2' => '2' },
        { 'C1' => '11', 'C2' => '12' },
        { 'C1' => '21', 'C2' => '22' }
    ],
    "NO03: check without headers and column names provided"
);

my $csv4 = Text::AutoCSV->new(
    in_file             => "t/${ww}hh1.csv",
    out_file            => $tmpf,
    has_headers         => 0,
    out_has_headers     => 1,
    fields_column_names => [ 'A', 'B', 'C' ]
)->write();
my $all4 = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
is_deeply(
    $all4,
    [
        { 'A' => '1',  'B' => '2',  'C' => undef },
        { 'A' => '11', 'B' => '12', 'C' => undef },
        { 'A' => '21', 'B' => '22', 'C' => undef }
    ],
    "NO04: check without headers and too many column names provided"
);

my $csv5 = Text::AutoCSV->new(
    in_file             => "t/${ww}hh1.csv",
    out_file            => $tmpf,
    has_headers         => 0,
    out_has_headers     => 1,
    fields_column_names => ['A'],
    out_sep_char        => ','
)->write();
my $all5 = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
is_deeply(
    $all5,
    [
        { 'A' => '1',  '__0001__' => '2' },
        { 'A' => '11', '__0001__' => '12' },
        { 'A' => '21', '__0001__' => '22' }
    ],
    "NO05: check without headers and too few column names provided"
);

my $csv6 = Text::AutoCSV->new(
    in_file             => "t/${ww}hh1.csv",
    out_file            => $tmpf,
    has_headers         => 0,
    out_has_headers     => 1,
    fields_column_names => [ '', 'A' ],
    out_sep_char        => ','
)->write();
my $all6 = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
is_deeply(
    $all6,
    [
        { '__0000__' => '1',  'A' => '2' },
        { '__0000__' => '11', 'A' => '12' },
        { '__0000__' => '21', 'A' => '22' }
    ],
    "NO06: check without headers and too few column names provided (2)"
);

Text::AutoCSV->new(
    in_file         => "t/${ww}hh2.csv",
    out_file        => $tmpf,
    out_has_headers => 0
)->write();
my $all7 =
  [ Text::AutoCSV->new( in_file => $tmpf, has_headers => 0 )->get_hr_all() ];
is_deeply(
    $all7,
    [
        { '__0000__' => '1',  '__0001__' => '2' },
        { '__0000__' => '11', '__0001__' => '12' },
        { '__0000__' => '21', '__0001__' => '22' }
    ],
    "NO07: check with headers and rewritten without"
);

unlink $tmpf if !$DEVTIME;

done_testing();

#
# Return the name of a temporary file name that is guaranteed NOT to exist.
#
# If ever it is not possible to return such a name (file exists and cannot be
# deleted), then stop execution.
sub get_non_existent_temp_file_name {
    my $tmpf = tmpnam();
    $tmpf = 'tmp0.csv' if $DEVTIME;

    unlink $tmpf if -f $tmpf;
    die
"File '$tmpf' already exists! Unable to delete it? Any way, tests aborted."
      if -f $tmpf;
    return $tmpf;
}

