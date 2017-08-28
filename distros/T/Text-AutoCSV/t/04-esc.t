#!/usr/bin/perl

# t/04-esc.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: escape character detection
#

use strict;
use warnings;

use Test::More tests => 29;

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

# * ********************************** *
# * escape_char explicit and detection *
# * ********************************** *

{
    note("");
    note("[ES]cape character management");

    my $csv = Text::AutoCSV->new(
        in_file        => "t/${ww}esc01.csv",
        croak_if_error => 0,
        escape_char    => '\\'
    );
    is( $csv->get_escape_char(), '\\', "ES01 - t/esc01.csv: backslah escape" );
    my $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => 'valc1',             'B' => 'valc2' },
            { 'A' => 'Val " ya " line 2', 'B' => 'val line 2' },
            { 'A' => '',                  'B' => '' }
        ],
        "ES02 - t/esc01.csv: backslah escape (2)"
    );

    $csv = Text::AutoCSV->new(
        in_file        => "t/${ww}esc02.csv",
        croak_if_error => 0,
        escape_char    => '"'
    );
    is( $csv->get_escape_char(), '"', "ES03 - t/esc01.csv: quote escape" );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => 'valc1',             'B' => 'valc2' },
            { 'A' => 'Val " ya " line 2', 'B' => 'val line 2' },
            { 'A' => '',                  'B' => '' }
        ],
        "ES04 - t/esc01.csv: quote escape (2)"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}esc01.csv", croak_if_error => 0 );
    is( $csv->get_escape_char(),
        '\\', "ES05 - t/esc01.csv: backslash escape, implicit" );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => 'valc1',             'B' => 'valc2' },
            { 'A' => 'Val " ya " line 2', 'B' => 'val line 2' },
            { 'A' => '',                  'B' => '' }
        ],
        "ES06 - t/esc01.csv: backslash escape, implicit (2)"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}esc02.csv", croak_if_error => 0 );
    is( $csv->get_escape_char(),
        '"', "ES07 - t/esc02.csv: quote escape, implicit" );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => 'valc1',             'B' => 'valc2' },
            { 'A' => 'Val " ya " line 2', 'B' => 'val line 2' },
            { 'A' => '',                  'B' => '' }
        ],
        "ES08 - t/esc02.csv: quote escape, implicit (2)"
    );
}

# * *************** *
# * out_escape_char *
# * *************** *

{
    note("");
    note("out_escape_char [WR]iting");

    my $tmpf = &get_non_existent_temp_file_name();
    my $tmp  = Text::AutoCSV->new(
        in_file        => "t/${ww}esc01.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    my $csv = Text::AutoCSV->new( in_file => $tmpf );
    is( $csv->get_escape_char(),
        '\\', "WR01 - reuse input escape character (backslash) in output" );

    $tmp = Text::AutoCSV->new(
        in_file         => "t/${ww}esc01.csv",
        croak_if_error  => 0,
        out_file        => $tmpf,
        out_escape_char => '"'
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    is( $csv->get_escape_char(), '"', "WR02 - out_escape_char => '\"'" );

    $tmp = Text::AutoCSV->new(
        in_file        => "t/${ww}esc02.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    is( $csv->get_escape_char(),
        '"', "WR03 - reuse input escape character (quote) in output" );

    $tmp = Text::AutoCSV->new(
        in_file         => "t/${ww}esc02.csv",
        croak_if_error  => 0,
        out_file        => $tmpf,
        out_escape_char => '\\'
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    is( $csv->get_escape_char(), '\\', "WR04 - out_escape_char => '\\'" );

    unlink $tmpf;
}

# * *********************** *
# * always_quote management *
# * *********************** *

{
    note("");
    note("[AL]ways_quote management");

    my $csv =
      Text::AutoCSV->new( in_file => "t/${ww}aq01.csv", croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        1, "AL01 - t/aq01.csv: CSV file always quoted" );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}aq02.csv", croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL02 - t/aq02.csv: CSV file not always quoted" );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}aq03.csv", croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL03 - t/aq03.csv: CSV file not always quoted" );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}aq04.csv", croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL04 - t/aq04.csv: CSV file not always quoted" );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}aq05.csv", croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL05 - t/aq05.csv: CSV file not always quoted" );

    my $tmpf = &get_non_existent_temp_file_name();
    Text::AutoCSV->new(
        in_file        => "t/${ww}aq01.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        1, "AL06 - t/aq01.csv: CSV file always quoted, rewrite" );

    Text::AutoCSV->new(
        in_file          => "t/${ww}aq01.csv",
        croak_if_error   => 0,
        out_file         => $tmpf,
        out_always_quote => 0
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0,
        "AL07 - t/aq01.csv: CSV file always quoted, rewrite without quotes" );

    Text::AutoCSV->new(
        in_file        => "t/${ww}aq02.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL08 - t/aq02.csv: CSV file not always quoted, rewrite" );

    Text::AutoCSV->new(
        in_file        => "t/${ww}aq03.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL09 - t/aq03.csv: CSV file not always quoted, rewrite" );

    Text::AutoCSV->new(
        in_file        => "t/${ww}aq04.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL10 - t/aq04.csv: CSV file not always quoted, rewrite" );

    Text::AutoCSV->new(
        in_file        => "t/${ww}aq05.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(),
        0, "AL11 - t/aq05.csv: CSV file not always quoted, rewrite" );

    Text::AutoCSV->new(
        in_file          => "t/${ww}aq02.csv",
        croak_if_error   => 0,
        out_file         => $tmpf,
        out_always_quote => 1
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(), 1,
"AL12 - t/aq02.csv: CSV file not always quoted, rewrite with always quote"
    );

    Text::AutoCSV->new(
        in_file          => "t/${ww}aq03.csv",
        croak_if_error   => 0,
        out_file         => $tmpf,
        out_always_quote => 1
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(), 1,
"AL13 - t/aq03.csv: CSV file not always quoted, rewrite with always quote"
    );

    Text::AutoCSV->new(
        in_file          => "t/${ww}aq04.csv",
        croak_if_error   => 0,
        out_file         => $tmpf,
        out_always_quote => 1
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(), 1,
"AL14 - t/aq04.csv: CSV file not always quoted, rewrite with always quote"
    );

    Text::AutoCSV->new(
        in_file          => "t/${ww}aq05.csv",
        croak_if_error   => 0,
        out_file         => $tmpf,
        out_always_quote => 1
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    is( $csv->get_is_always_quoted(), 1,
"AL15 - t/aq05.csv: CSV file not always quoted, rewrite with always quote"
    );

    unlink $tmpf;
}

done_testing();

#
# Return the name of a temporary file name that is guaranteed NOT to exist.
#
# If ever it is not possible to return such a name (file exists and cannot be
# deleted), then stop execution.
sub get_non_existent_temp_file_name {
    my $tmpf = tmpnam();
    $tmpf = 'tmp0.csv' if $DEVTIME;

    if ( -f $tmpf ) {
        note("* WARNING *");
        note(
"Deleting file '$tmpf' before starting test. Strange this file already exists!"
        );
        unlink $tmpf;
    }
    die
"File '$tmpf' already exists! Unable to delete it? Any way, tests aborted."
      if -f $tmpf;

    return $tmpf;
}

