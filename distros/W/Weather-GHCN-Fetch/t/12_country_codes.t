# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 2;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Const::Fast;

use Weather::GHCN::CountryCodes qw( get_country_by_gec search_country );

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';


subtest 'get_country_by_gec' => sub {

    my $href;

    $href = get_country_by_gec('CA');
    is $href->{name},    'Canada',      'CA name';
    is $href->{gec},     'CA',          'CA get';
    is $href->{iso2},    'CA',          'CA iso2';
    is $href->{iso3},    'CAN',         'CA iso3';
    is $href->{isonum},  124,           'CA isonum';
    is $href->{nato},    'CAN',         'CA nato';
    is $href->{internet},'.ca',         'CA internet';
    is $href->{comment}, '',            'CA comment';

    $href = get_country_by_gec('AY');
    is $href->{name},    'Antarctica',   'AY name';
    is $href->{gec},     'AY',           'AY get';
    is $href->{iso2},    'AQ',           'AY iso2';
    is $href->{iso3},    'ATA',          'AY iso3';
    is $href->{isonum},  10,             'AY isonum';
    is $href->{nato},    'ATA',          'AY nato';
    is $href->{internet},'.aq',          'AY internet';
    is $href->{comment}, 'ISO defines as the territory south of 60 degrees south latitude',
                                         'AY comment';

    $href = get_country_by_gec('INVALID');
    # ok !defined $href, 'An invalid GEC return an undef';
    ok $href eq '', 'An invalid GEC returns an empty string';
    
    $href = get_country_by_gec('-');
    ok $href eq '', "A GEC of '-' returns an empty string";
    
};

subtest 'search_country' => sub {

    my @href;

    @href = search_country('Bel', 'name');
    is @href, 3, "Search for 'Bel' by name returned 3 results";
    is $href[0]->{name}, 'Belarus', 'First value returned is Belarus';

    @href = search_country('CH', 'gec');
    is $href[0]->{gec},    'CH', 'Search by gec for CH China';

    @href = search_country('CHN', 'iso3');
    is $href[0]->{iso3},   'CHN', 'Search by iso3 for CHN China';

    @href = search_country(40, 'isonum');
    is $href[0]->{isonum}, 40, 'Search by isonum for 40 Austria';

    @href = search_country('ANT', 'nato');
    is $href[0]->{nato},   'ANT', 'Search by nato for ANT Netherlands Antilles';

    @href = search_country('.ir', 'internet');
    is $href[0]->{internet},'.ir', 'Search by internet for .ir Iran';

    @href = search_country('CG', 'gec');
    is $href[0]->{gec},    'CG', 'Search by gec for CG Congo (formerly Zaire) and return notes';
    is $href[0]->{comment},'formerly Zaire', 'Comment for CG Congo (formerly Zaire)';

    # now search without giving a specific field
    
    @href = search_country('CH', undef);
    is $href[0]->{gec},    'CH', 'Search by guess (gec) for CH China';

    @href = search_country('CCK', undef);
    is $href[0]->{iso3},   'CCK', 'Search by guess (iso3) for CCK Cocos (Keeling) Islands';

    @href = search_country(40, undef);
    is $href[0]->{isonum}, 40, 'Search by guess (isonum) for 40 Austria';

    @href = search_country('ANT', undef);
    is $href[0]->{nato},   undef, 'Search by guess (nato but iso3 takes precedence) for ANT Netherlands Antilles';

    @href = search_country('.ir', undef);
    is $href[0]->{internet},'.ir', 'Search by gues (internet) for .ir Iran';

    @href = search_country('United', undef);
    is @href, 3, "Search for 'United' defaulted to name and returned multiple results";
    is $href[0]->{name}, 'United Arab Emirates', 'First value returned is United Arab Emirates';

    throws_ok
        { search_country('XXX', 'invalid_fieldname') }
        qr/invalid search field name/,
        'invalid search field name';
};