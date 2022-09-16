# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 5;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Const::Fast;
#use Set::IntSpan::Fast;

use Weather::GHCN::Common qw( :all );

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';

subtest 'commify tests' => sub {

    is commify(undef),           $EMPTY,         'commify()';
    is commify(9),               '9',            'commify(9)';
    is commify(99),              '99',           'commify(99)';
    is commify(999),             '999',          'commify(999)';
    is commify(9999),            '9,999',        'commify(9999)';
    is commify(99999),           '99,999',       'commify(99999)';
    is commify(999999),          '999,999',      'commify(999999)';
    is commify(9999999),         '9,999,999',    'commify(9999999)';
    is commify(9999999.99),      '9,999,999.99', 'commify(9999999.99)';
    is commify(9999999.9999),    '9,999,999.9999','commify(9999999.9999)';
    is commify('abcd'),          'abcd',         q|commify('abcd')|;
    is commify('$9,999.00CR'),   '$9,999.00CR',  q|commify('$9,999.00CR')|;
    is commify('$9999.00CR'),    '$9,999.00CR',  q|commify('$9999.00CR')|;
};

subtest 'iso_date_time tests' => sub {

    # simulating the return list of localtime, which is
    #   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    my @local_dt = (0,29,13,4,0,120,6,3,0);

    is iso_date_time(@local_dt), '2020-01-04 13:29:00','iso_date_time as scalar';

    my @ymdhms = iso_date_time(@local_dt);
    is $ymdhms[0], 2020, 'iso_date_time as list (year)';
    is $ymdhms[1],    1, 'iso_date_time as list (month)';
    is $ymdhms[2],    4, 'iso_date_time as list (day)';
    is $ymdhms[3],   13, 'iso_date_time as list (hour)';
    is $ymdhms[4],   29, 'iso_date_time as list (min)';
    is $ymdhms[5],   00, 'iso_date_time as list (sec)';
};

subtest 'rng tests' => sub {
    my $r = rng_new('1-5');

    isa_ok $r, 'Set::IntSpan::Fast', "rng_new('1-5')";

    is rng_valid('9'),          $TRUE, 'range 9 is valid';
    is rng_valid('1-5'),        $TRUE, 'range 1-5 is valid';
    is rng_valid('1,3,5,7-9'),  $TRUE, 'range 1,3,5,7-9 is valid';
    is rng_valid('9-0'),        $TRUE, 'range "9-0" is valid';

    isnt rng_valid(''),         $TRUE, 'range "" is invalid';
    isnt rng_valid('X'),        $TRUE, 'range "X" is invalid';
    isnt rng_valid('1..3'),     $TRUE, 'range "1..3" is invalid';

    is rng_within('3-5', '0-9'),$TRUE, "range '3-5' is within '0-9'";
    is rng_within('0-9', '0-9'),$TRUE, "range '0-9' is within '0-9'";
    is rng_within('0', '0-9'),  $TRUE, "range '0' is within '0-9'";
    is rng_within('5', '0-9'),  $TRUE, "range '5' is within '0-9'";
    is rng_within('9', '0-9'),  $TRUE, "range '9' is within '0-9'";

    isnt rng_within('1-3', '5-9'),$TRUE, "range '1-3' is not within '5-9'";
    isnt rng_within('5-9', '1-3'),$TRUE, "range '5-9' is not within '1-3'";
    isnt rng_within('0-5', '2-9'),$TRUE, "range '0-9' is not within '2-9'";
    isnt rng_within('7-9', '1-7'),$TRUE, "range '7-9' is not within '1-7'";
    
    # for test coverage
    is rng_new(undef)->as_string, rng_new('')->as_string, 'rng_new(undef)';
    
    throws_ok
        { rng_within('invalid_range', '1-5') }
        qr/invalid range argument/,
        'rng_within invalid range';
        
    throws_ok
        { rng_within('1-5', 'invalid_domain') }
        qr/invalid domain argument/,
        'rng_within invalid domain';
        
};

subtest 'tsv tests' => sub {
    my $tsv;

    my @list = ( qw/ a b c /);
    
    $tsv = tsv(\@list);
    is $tsv, "a\nb\nc", 'tsv list';

    my $lol = [
        [ 'a' ],
        [ 'b' ],
    ];

    $tsv = tsv($lol);

    is $tsv, "a\nb", 'tsv list of lists';

    is tsv(undef), $EMPTY, 'tsv undef';
    is tsv([]),    $EMPTY, "tsv []";
    is tsv( ['', 'xxx'] ), "\nxxx", "tsv ['','xxx']";
    
    throws_ok
        { tsv( [ {} ] ) }
        qr/invalid argument/,
        "tsv( [ {} ])"
};

subtest 'iso_date_time tests' => sub {
    #         $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    my @dt = (10,  15,  13,   2,    8,   122,  5,    244,  1);
    
    my $got = iso_date_time(@dt);
    my $expected = '2022-09-02 13:15:10';

    is $got, $expected, 'iso_date_time';
    
    throws_ok
        { iso_date_time() }
        qr/requires at least a 6-element localtime array/,
        'iso_date_time() is invalid';
    
    throws_ok
        { iso_date_time('2022-08-30') }
        qr/requires at least a 6-element localtime array/,
        "iso_date_time('2022-08-30') is invalid";
    
    SKIP: {
        # iso_date_time doesn't do any argument validation
        # it just takes a localtime list and makes the argumets
        # useable and printable, for example by converting localtime's
        # 1900-based year 3-digit year to YYYY, and by making month
        # and day numbers 1-based.
        skip "argument validation";
        # try invalid month number (14)
        throws_ok
            { iso_date_time(10,15,13,   2,14,122,  5,244,1) }
            qr/some kind of error/,
            "iso_date_time doesn't validate month";

        # try invalid day number (32)
        throws_ok
            { iso_date_time(10,15,13,   32,8,122,  5,244,1) }
            qr/some kind of error/,
            "iso_date_time doesn't validate day";

        # try invalid year number (years are yyyy-1900, so try 2022)
        throws_ok
            { iso_date_time(10,15,13,   2,8,2022,  5,244,1) }
            qr/some kind of error/,
            "iso_date_time doesn't validate day";
    };    
};