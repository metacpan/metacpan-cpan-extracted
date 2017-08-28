#!/usr/bin/perl

# t/13-accents.t

#
# Written by Sébastien Millet
# September 2016
#

#
# Test script for Text::AutoCSV: fields with accents
#

use strict;
use warnings;

use utf8;

use Test::More tests => 40;

#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !!( $^O =~ /mswin/i );
my $ww = ( $OS_IS_PLAIN_WINDOWS ? 'ww' : '' );

# FIXME
# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
    use_ok('Text::AutoCSV');
}

can_ok( 'Text::AutoCSV', ('new') );

note("");
note("[AC]cents in field names");

my $csv = Text::AutoCSV->new( in_file => "t/${ww}acct-l1.csv" );
is( $csv->get_in_encoding(),
    'latin1', "AC01: latin1: check encoding detection" );
my $f = [ $csv->get_fields_names() ];
is_deeply(
    $f,
    [
        'ELEMENTAIRE', 'ETREOUNEPASETRE', 'CHATEAU', 'HOPITAL',
        'AMBIGUE',     'METRE'
    ],
    "AC02: latin1: check field names when input has accents"
);

$csv =
  Text::AutoCSV->new( in_file => "t/${ww}acct-l2.csv", encoding => 'latin2' );
$f = [ $csv->get_fields_names() ];
is_deeply(
    $f,
    [ 'U', 'E', 'NECI' ],
    "AC03: latin2: check field names when input has accents"
);

$csv = Text::AutoCSV->new( in_file => "t/${ww}acct-ub.csv" );
is( $csv->get_in_encoding(), 'UTF-8', "AC04: UTF-8: check encoding detection" );
$f = [ $csv->get_fields_names() ];
is_deeply(
    $f,
    [
        'U',               'E',       'NECI',    'ELEMENTAIRE',
        'ETREOUNEPASETRE', 'CHATEAU', 'HOPITAL', 'AMBIGUE',
        'METRE'
    ],
    "AC05: UTF-8 (BOM): check field names when input has accents"
);

$csv = Text::AutoCSV->new( in_file => "t/${ww}acct2.csv" );
is( $csv->get_in_encoding(),
    'UTF-8', "AC06: UTF-8: check encoding detection (2)" );
$f = [ $csv->get_fields_names() ];
is_deeply(
    $f,
    [ 'A', 'CŒURETRE', 'N' ],
"AC07: UTF-8 (BOM): field names with special character (non us-ascci) not an accent"
);

$csv = Text::AutoCSV->new( in_file => "t/${ww}accx.csv" );
is( $csv->get_in_encoding(),
    'UTF-8', "AC08 - t/accx.csv: check input encoding detection" );

# latin1 char
my $v = $csv->vlookup( 'A', 'etre', 'C' );
is( $v, '10', "AC09 - t/accx.csv: vlookup with accent" );
$v = $csv->vlookup( 'A', 'etre', 'C', { ignore_accents => 0 } );
is( $v, '12', "AC10 - t/accx.csv: vlookup with accent, ignore_accents => 0" );
$v = $csv->vlookup( 'A', 'être', 'C' );
is( $v, '10', "AC11 - t/accx.csv: vlookup with accent" );
$v = $csv->vlookup( 'A', 'être', 'C', { ignore_accents => 0 } );
is( $v, '10', "AC12 - t/accx.csv: vlookup with accent, ignore_accents => 0" );

# latin2 char
$v = $csv->vlookup( 'B', 'Sluzba', 'C' );
is( $v, '10', "AC13 - t/accx.csv: vlookup with accent (2)" );
$v = $csv->vlookup( 'B', 'Sluzba', 'C', { ignore_accents => 0 } );
is( $v, '10',
    "AC14 - t/accx.csv: vlookup with accent, ignore_accents => 0 (2)" );
$v = $csv->vlookup( 'B', 'služba', 'C' );
is( $v, '10', "AC15 - t/accx.csv: vlookup with accent (2)" );
$v = $csv->vlookup( 'B', 'služba', 'C', { ignore_accents => 0 } );
is( $v, '11',
    "AC16 - t/accx.csv: vlookup with accent, ignore_accents => 0 (2)" );

$csv = Text::AutoCSV->new(
    in_file               => "t/${ww}accx.csv",
    search_ignore_accents => 0
);
is( $csv->get_in_encoding(),
    'UTF-8', "AC17 - t/accx.csv: check input encoding detection" );

# latin1 char
$v = $csv->vlookup( 'A', 'etre', 'C' );
is( $v, '12', "AC18 - t/accx.csv: vlookup with accent" );
$v = $csv->vlookup( 'A', 'etre', 'C', { ignore_accents => 1 } );
is( $v, '10', "AC19 - t/accx.csv: vlookup with accent, ignore_accents => 0" );
$v = $csv->vlookup( 'A', 'être', 'C' );
is( $v, '10', "AC20 - t/accx.csv: vlookup with accent" );
$v = $csv->vlookup( 'A', 'être', 'C', { ignore_accents => 1 } );
is( $v, '10', "AC21 - t/accx.csv: vlookup with accent, ignore_accents => 0" );

# latin2 char
$v = $csv->vlookup( 'B', 'Sluzba', 'C' );
is( $v, '10', "AC22 - t/accx.csv: vlookup with accent (2)" );
$v = $csv->vlookup( 'B', 'Sluzba', 'C', { ignore_accents => 1 } );
is( $v, '10',
    "AC23 - t/accx.csv: vlookup with accent, ignore_accents => 0 (2)" );
$v = $csv->vlookup( 'B', 'služba', 'C' );
is( $v, '11', "AC24 - t/accx.csv: vlookup with accent (2)" );
$v = $csv->vlookup( 'B', 'služba', 'C', { ignore_accents => 1 } );
is( $v, '10',
    "AC25 - t/accx.csv: vlookup with accent, ignore_accents => 0 (2)" );

# Header contains no separator but only alnum -> success
$csv = Text::AutoCSV->new( in_file => "t/${ww}accy.csv" );
$f = [ $csv->get_fields_names() ];
is_deeply(
    $f,
    ['UN_CŒUR_EN_HIVER10_ETRE_POLE_OU'],
    "AC26 - t/accy.csv: unique field CSV management"
);

# 1: check failure if only alnum chars + one space
# 2: check failure if only alnum chars + '!'
# 3: check failure if only alnum chars + '/'
# 4: check failure if only alnum chars + '$'
# 5: check failure if only alnum chars + ':'
# 6: check failure if only alnum chars + '-'
for my $i ( 1 .. 6 ) {
    my $inp         = "t/${ww}accz${i}.csv";
    my $eval_failed = 0;
    eval {
        $csv = Text::AutoCSV->new( in_file => $inp );
        $f = [ $csv->get_fields_names() ];
    } or $eval_failed = 1;
    is( $eval_failed, 1, "$inp: check eval failed ($i)" );
    like(
        $@,
        qr/cannot detect CSV separator/i,
        "$inp: check error message ($i)"
    );
}

done_testing();

