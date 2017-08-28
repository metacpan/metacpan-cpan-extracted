#!/usr/bin/perl

# t/16-outhh.t

#
# Written by Sébastien Millet
# July 2017
#

#
# Test script for Text::AutoCSV: new 1.1.9 features:
#   out_orderby, multiline info, get_nb_rows
#

use strict;
use warnings;

use Test::More tests => 6;

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
note("[OR]der fields");

my $csv = Text::AutoCSV->new(
    in_file     => "t/${ww}misc1.csv",
    out_file    => $tmpf,
    out_orderby => [ 'A', 'B' ]
);
my $all = [ $csv->get_hr_all() ];
is_deeply(
    $all,
    [
        { 'A' => '18', 'B' => 'l2', 'C' => 'l2' },
        { 'A' => '06', 'B' => 'z3', 'C' => '' },
        { 'A' => '20', 'B' => '',   'C' => 'l4' },
        { 'A' => '03', 'B' => '',   'C' => '' },
        { 'A' => '06', 'B' => 'l6', 'C' => 'l6' }
    ],
    "OR01: check input"
);
$csv->write();

my $all2 = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
is_deeply(
    $all2,
    [
        { 'A' => '03', 'B' => '',   'C' => '' },
        { 'A' => '06', 'B' => 'l6', 'C' => 'l6' },
        { 'A' => '06', 'B' => 'z3', 'C' => '' },
        { 'A' => '18', 'B' => 'l2', 'C' => 'l2' },
        { 'A' => '20', 'B' => '',   'C' => 'l4' }
    ],
    "OR02: check after re-ordered write"
);

note("");
note("[MU]ltiline fields detection");

my $coldata =
  [ Text::AutoCSV->new( in_file => "t/${ww}misc2.csv" )->get_coldata() ];
is_deeply(
    $coldata,
    [
        [ 'A', 'a', '', undef, undef, '1' ],
        [ 'B', 'b', '', undef, undef, 'm' ],
        [ 'C', 'c', '', undef, undef, '1' ],
        [ 'D', 'd', '', undef, undef, 'm' ]
    ],
    "MU01: check multiline fields are well detected"
);

my $nb_rows =
  Text::AutoCSV->new( in_file => "t/${ww}misc2.csv" )->get_nb_rows();
is( $nb_rows, 6, "MU02: check row count while some fields are multiline" );

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

