#!/usr/bin/perl

# t/07-dates1.t

#
# Written by Sébastien Millet
# June, July 2016
#

#
# Test script for Text::AutoCSV: dates management, part 1
#

use strict;
use warnings;

use Test::More tests => 20;

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

{
    note("");
    note("[BA]sic date tests");

    my $csv = Text::AutoCSV->new(
        in_file      => "t/${ww}dates1-0.csv",
        fields_dates => ['D']
    );
    my $d = $csv->_dds();
    is_deeply(
        $d,
        { '.' => 1, 'D' => '%d/%m/%Y' },
        "BA01 - simple date dd/mm/yyyy column"
    );

    $csv = Text::AutoCSV->new(
        in_file           => "t/${ww}dates1-0.csv",
        fields_dates_auto => 1
    );
    $d = $csv->_dds();
    is_deeply(
        $d,
        { '.' => 0, 'D' => '%d/%m/%Y', 'E' => 'N', 'F' => 'Z' },
        "BA02 - simple date dd/mm/yyyy column"
    );

    $csv = Text::AutoCSV->new(
        in_file      => "t/${ww}dates1-0.csv",
        fields_dates => ['D']
    );
    $d = $csv->_dds();
    is_deeply(
        $d,
        { '.' => 1, 'D' => '%d/%m/%Y' },
        "BA03 - specify field that contains a date"
    );

    my $w = 0;
    eval {
        local $SIG{__WARN__} = sub { $w++ };
        $csv = Text::AutoCSV->new(
            in_file        => "t/${ww}dates1-0.csv",
            fields_dates   => ['E'],
            croak_if_error => 0
        );
        $d = $csv->_dds();
    } or $w = -10;
    is_deeply(
        $d,
        { '.' => 1, 'E' => 'N' },
        "BA04 - specify field that contains a date, date format not found"
    );
    is( $w, 2,
        "BA05 - check a warning got raised due to the format not found" );

    $w = 0;
    eval {
        local $SIG{__WARN__} = sub { $w++ };
        $csv = Text::AutoCSV->new(
            in_file        => "t/${ww}dates1-0.csv",
            fields_dates   => [ 'D', 'E', 'F' ],
            croak_if_error => 0
        );
        $d = $csv->_dds();
    } or $w = -10;
    is_deeply(
        $d,
        { '.' => 0, 'D' => '%d/%m/%Y', 'E' => 'N', 'F' => 'Z' },
"BA06 - specify field that contains a date, date format not found (1) and found (1)"
    );
    is( $w, 3,
        "BA07 - check a warning got raised due to the format not found" );

    $w = 0;
    eval {
        local $SIG{__WARN__} = sub { $w++ };
        $csv = Text::AutoCSV->new(
            in_file      => "t/${ww}dates1-0.csv",
            fields_dates => [ 'D', 'E', 'F' ]
        );
        $d = $csv->_dds();
    } or $w += 100;
    is_deeply(
        $d,
        { '.' => 0, 'D' => '%d/%m/%Y', 'E' => 'N', 'F' => 'Z' },
"BA08 - specify field that contains a date, date format not found (1) and found (1)"
    );
    is( $w, 102,
        "BA09 - check a warning got raised due to the format not found" );

    $w = 0;
    eval {
        local $SIG{__WARN__} = sub { $w++ };
        $csv = Text::AutoCSV->new(
            in_file      => "t/${ww}dates1-0.csv",
            fields_dates => [ 'D', 'E', 'BADNAME' ],
            infoh        => undef
        )->_dds();
    } or $w += 100;
    is( $w, 101,
"BA10 - check an error is raised if wrong field name given to fields_dates"
    );
}

note("");
note("[SU]pplementary formats");

my $s = [
    Text::AutoCSV->new(
        in_file           => "t/${ww}dates1-1.csv",
        fields_dates_auto => 1
    )->_dds()
];
is_deeply(
    $s,
    [ { '.' => 2, 'A' => '%d/%m/%y', 'B' => 'N', 'C' => 'N', 'D' => 'N' } ],
    "SU01 - t/dates1-1.csv': attribute dates_formats_to_try_supp (1)"
);

$s = [
    Text::AutoCSV->new(
        in_file                   => "t/${ww}dates1-1.csv",
        fields_dates_auto         => 1,
        dates_formats_to_try_supp => ['XX%d%m%yYY']
    )->_dds()
];
is_deeply(
    $s,
    [
        {
            '.' => 2,
            'A' => '%d/%m/%y',
            'B' => 'XX%d%m%yYY',
            'C' => 'N',
            'D' => 'N'
        }
    ],
    "SU02 - t/dates1-1.csv': attribute dates_formats_to_try_supp (2)"
);

$s = [
    Text::AutoCSV->new(
        in_file                   => "t/${ww}dates1-1.csv",
        fields_dates_auto         => 1,
        dates_formats_to_try_supp => [ 'XX%d%m%yYY', '%Y+%m+%d' ]
    )->_dds()
];
is_deeply(
    $s,
    [
        {
            '.' => 2,
            'A' => '%d/%m/%y',
            'B' => 'XX%d%m%yYY',
            'C' => 'N',
            'D' => '%Y+%m+%d'
        }
    ],
    "SU03 - t/dates1-1.csv': attribute dates_formats_to_try_supp (3)"
);

$s = [
    Text::AutoCSV->new(
        in_file              => "t/${ww}dates1-1.csv",
        fields_dates_auto    => 1,
        dates_formats_to_try => [ 'XX%d%m%yYY', '%Y+%m+%d' ]
    )->_dds()
];
is_deeply(
    $s,
    [
        {
            '.' => 1,
            'A' => 'N',
            'B' => 'XX%d%m%yYY',
            'C' => 'N',
            'D' => '%Y+%m+%d'
        }
    ],
    "SU04 - t/dates1-1.csv': attribute dates_formats_to_try_supp (4)"
);

$s = [
    Text::AutoCSV->new(
        in_file           => "t/${ww}dates1-2.csv",
        fields_dates_auto => 1
    )->_dds()
];
is_deeply(
    $s,
    [ { '.' => 1, 'A' => '%d/%m/%Y', 'B' => '%Y%m%d%H%M%S' } ],
    "SU05 - t/dates1-2.csv': new format '%Y%m%d%H%M%S'"
);

note("");
note("[OP]timization (fields_dates_auto_optimize)");

my $csv = Text::AutoCSV->new(
    in_file                    => "t/${ww}dates1-3.csv",
    fields_dates_auto          => 1,
    fields_dates_auto_optimize => 1
);
my $d = $csv->_dds();
is_deeply(
    $d,
    { '.' => 1, 'D' => '%d/%m/%Y', 'E' => 'N', 'F' => 'N' },
    "OP01 - identifies format if fields_dates_auto_optimize is set"
);

my $csv2 = Text::AutoCSV->new(
    in_file                    => "t/${ww}dates1-3.csv",
    fields_dates_auto          => 1,
    fields_dates_auto_optimize => 0
);
my $d2 = $csv2->_dds();
is_deeply(
    $d2,
    { '.' => 1, 'D' => 'N', 'E' => 'N', 'F' => 'N' },
    "OP02 - identifies format if fields_dates_auto_optimize is unset"
);

$csv2 = Text::AutoCSV->new(
    in_file           => "t/${ww}dates1-3.csv",
    fields_dates_auto => 1
);
$d2 = $csv2->_dds();
is_deeply(
    $d2,
    { '.' => 1, 'D' => 'N', 'E' => 'N', 'F' => 'N' },
    "OP03 - identifies format (default)"
);

done_testing();

