#!perl

use strict;
use Config;
use FindBin qw( $Bin );
use Readonly;
use Test::More;
use File::Spec::Functions;

Readonly my $TEST_COUNT    => 13;
Readonly my $PERL          => $^X;
Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );
Readonly my $TABLIFY       => catfile($Bin, '..', qw/bin tablify/);

plan tests => $TEST_COUNT;

ok( -e $TABLIFY, 'Script exists' );

SKIP: {
    eval { require Text::TabularDisplay };

    if ($@) {
        skip 'Text::TabularDisplay not installed', $TEST_COUNT - 1;
    }

    my $data = catfile( $TEST_DATA_DIR, 'people.dat' );
    ok( -e $data, 'Data file exists' );

    my $nh_data = catfile( $TEST_DATA_DIR, 'people-no-header.dat' );
    ok( -e $nh_data, 'Other data file exists' );

    my @tests = (
    {
        name     => 'Field list',
        args     => "--fs ',' -l $data",
        expected => 
    '+-----------+-----------+
    | Field No. | Field     |
    +-----------+-----------+
    | 1         | name      |
    | 2         | rank      |
    | 3         | serial_no |
    | 4         | is_living |
    | 5         | age       |
    +-----------+-----------+
    '
    },
    {
        name     => 'Select fields by name',
        args     => "--fs ',' -f name,serial_no $data",
        expected => 
    '+--------+-----------+
    | name   | serial_no |
    +--------+-----------+
    | George | 190293    |
    | Dwight | 908348    |
    | Attila |           |
    | Tojo   |           |
    | Tommy  | 998110    |
    +--------+-----------+
    5 records returned
    '
    },
    {
        name     => 'Limit',
        args     => "--fs ',' --limit 2 -f name,serial_no $data",
        expected => 
    '+--------+-----------+
    | name   | serial_no |
    +--------+-----------+
    | George | 190293    |
    | Dwight | 908348    |
    +--------+-----------+
    2 records returned
    '
    },
    {
        name     => 'Select fields by position',
        args     => "--fs ',' -f 1-3,5 $data",
        expected => 
    '+--------+---------+-----------+------+
    | name   | rank    | serial_no | age  |
    +--------+---------+-----------+------+
    | George | General | 190293    | 64   |
    | Dwight | General | 908348    | 75   |
    | Attila | Hun     |           | 56   |
    | Tojo   | Emporor |           | 87   |
    | Tommy  | General | 998110    | 54   |
    +--------+---------+-----------+------+
    5 records returned
    '
    },
    {
        name     => 'Filter with regex',
        args     => "--fs ',' -w 'serial_no=~/^\\d{6}\$/' $data",
        expected => 
    '+--------+---------+-----------+-----------+------+
    | name   | rank    | serial_no | is_living | age  |
    +--------+---------+-----------+-----------+------+
    | George | General | 190293    | 0         | 64   |
    | Dwight | General | 908348    | 0         | 75   |
    | Tommy  | General | 998110    | 1         | 54   |
    +--------+---------+-----------+-----------+------+
    3 records returned
    '
    },
    {
        name     => 'Filter with Perl operator',
        args     => "--fs ',' -w 'name eq \"Dwight\"' $data",
        expected => 
    '+--------+---------+-----------+-----------+------+
    | name   | rank    | serial_no | is_living | age  |
    +--------+---------+-----------+-----------+------+
    | Dwight | General | 908348    | 0         | 75   |
    +--------+---------+-----------+-----------+------+
    1 record returned
    '
    },
    {
        name     => 'Combine filter and field selection',
        args     => "--fs ',' -f name -w 'is_living==1' ".
                    "-w 'serial_no>0' $data",
        expected => 
    '+-------+
    | name  |
    +-------+
    | Tommy |
    +-------+
    1 record returned
    '
    },
    {
        name     => 'No headers plus filtering by position',
        args     => "--fs ',' --no-headers -w '3 eq \"General\"' $nh_data",
        expected => 
        '+--------+---------+--------+--------+--------+
        | Field1 | Field2  | Field3 | Field4 | Field5 |
        +--------+---------+--------+--------+--------+
        | George | General | 190293 | 0      | 64     |
        | Dwight | General | 908348 | 0      | 75     |
        | Tommy  | General | 998110 | 1      | 54     |
        +--------+---------+--------+--------+--------+
        3 records returned
        '
    },
    {
        name     => 'Vertical display',
        args     => "--fs ',' -v $data",
        no_strip => 1,
        expected => 
'************ Record 1 ************
     name: George
     rank: General
serial_no: 190293
is_living: 0
     age : 64
************ Record 2 ************
     name: Dwight
     rank: General
serial_no: 908348
is_living: 0
     age : 75
************ Record 3 ************
     name: Attila
     rank: Hun
serial_no: 
is_living: 0
     age : 56
************ Record 4 ************
     name: Tojo
     rank: Emporor
serial_no: 
is_living: 0
     age : 87
************ Record 5 ************
     name: Tommy
     rank: General
serial_no: 998110
is_living: 1
     age : 54

5 records returned
'
    },
    {
        name     => 'No headers, vertical display',
        args     => "--fs ',' --no-headers -v --limit 1 $nh_data",
        no_strip => 1,
        expected => 
'************ Record 1 ************
Field1: George
Field2: General
Field3: 190293
Field4: 0
Field5: 64

1 record returned
'
    },
    );

    my $command = "$PERL $TABLIFY ";
    for my $test ( @tests ) {
        my $out = `$command $test->{'args'}`;
        unless ( $test->{'no_strip'} ) {
            $test->{'expected'} =~ s/^\s*//xmsg;
        }
        is( $out, $test->{'expected'}, $test->{'name'} || 'Parsing' );
    }
};
