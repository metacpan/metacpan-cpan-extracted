# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::StationTable;

package Weather::GHCN::StationTable;

use Test::More tests => 8;
use Test::Exception;

use Const::Fast;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';

subtest 'undef-safe numeric functions' => sub {

    is _dcount(undef,undef),undef, '_dcount(undef,undef)';
    is _dcount(undef,9),    1,     '_dcount(undef,9)';
    is _dcount(1,undef),    1,     '_dcount(1,undef)';
    is _dcount(1,9),        2,     '_dcount(1,9)';
    is _dcount(9,1),        10,    '_dcount(9,1)';
    is _dcount(9,9),        10,    '_dcount(9,9)';

    is _ddivide(undef,undef), undef, '_ddivide(undef,undef)';
    is _ddivide(undef,9),     undef, '_ddivide(undef,9)';
    is _ddivide(1,undef),     undef, '_ddivide(1,undef)';
    is _ddivide(1,0),         undef, '_ddivide(1,0)';
    is _ddivide(5,10),        0.5,   '_ddivide(5,10)';
    is _ddivide(10,5),        2,     '_ddivide(10,5)';
    is _ddivide(9,9),         1,     '_ddivide(9,9)';

    is _dmax(undef,undef),undef, '_dmax(undef,undef)';
    is _dmax(undef,9),    9,     '_dmax(undef,9)';
    is _dmax(1,undef),    1,     '_dmax(1,undef)';
    is _dmax(1,9),        9,     '_dmax(1,9)';
    is _dmax(9,1),        9,     '_dmax(9,1)';
    is _dmax(9,9),        9,     '_dmax(9,9)';

    is _dmin(undef,undef),undef, '_dmin(undef,undef)';
    is _dmin(undef,9),    9,     '_dmin(undef,9)';
    is _dmin(1,undef),    1,     '_dmin(1,undef)';
    is _dmin(1,9),        1,     '_dmin(1,9)';
    is _dmin(9,1),        1,     '_dmin(9,1)';
    is _dmin(9,9),        9,     '_dmin(9,9)';

    is _dsum(undef,undef),undef, '_dsum(undef,undef)';
    is _dsum(undef,9),    9,     '_dsum(undef,9)';
    is _dsum(1,undef),    1,     '_dsum(1,undef)';
    is _dsum(1,9),        10,    '_dsum(1,9)';
    is _dsum(9,1),        10,    '_dsum(9,1)';
    is _dsum(9,9),        18,    '_dsum(9,9)';
};

subtest 'date functions' => sub {

    is _days_in_year(1889), 365, '_days_in_year 1889';
    is _days_in_year(1900), 365, '_days_in_year 1900';
    is _days_in_year(1901), 365, '_days_in_year 1901';
    is _days_in_year(1904), 366, '_days_in_year 1904';
    is _days_in_year(2000), 366, '_days_in_year 2000';
    is _days_in_year(2004), 366, '_days_in_year 2004';
    is _days_in_year(2005), 365, '_days_in_year 2005';

    is _days_in_month(1889, 10),31, '_days_in_month 1889-10';
    is _days_in_month(2019, 1), 31, '_days_in_month 2019-01';
    is _days_in_month(2019, 2), 28, '_days_in_month 2019-02';
    is _days_in_month(2019, 3), 31, '_days_in_month 2019-03';
    is _days_in_month(2019, 4), 30, '_days_in_month 2019-04';
    is _days_in_month(2019, 5), 31, '_days_in_month 2019-05';
    is _days_in_month(2019, 6), 30, '_days_in_month 2019-06';
    is _days_in_month(2019, 7), 31, '_days_in_month 2019-07';
    is _days_in_month(2019, 8), 31, '_days_in_month 2019-08';
    is _days_in_month(2019, 9), 30, '_days_in_month 2019-09';
    is _days_in_month(2019,10), 31, '_days_in_month 2019-10';
    is _days_in_month(2019,11), 30, '_days_in_month 2019-11';
    is _days_in_month(2019,12), 31, '_days_in_month 2019-12';
    is _days_in_month(2020, 2), 29, '_days_in_month 2020-02';

    is _is_leap_year(1600), 1, '_is_leap_year 1600 is';
    is _is_leap_year(1889), 0, '_is_leap_year 1889 isnt';
    is _is_leap_year(1900), 0, '_is_leap_year 1900 isnt';
    is _is_leap_year(1901), 0, '_is_leap_year 1901 isnt';
    is _is_leap_year(1904), 1, '_is_leap_year 1904 is';
    is _is_leap_year(2000), 1, '_is_leap_year 2000 is';
    is _is_leap_year(2004), 1, '_is_leap_year 2004 is';
    is _is_leap_year(2005), 0, '_is_leap_year 2005 isnt';
    is _is_leap_year(2100), 0, '_is_leap_year 2100 isnt';

    is _seasonal_qtr(2018,11), 'Q4', '_seasonal_qtr 2018-11';
    is _seasonal_qtr(2018,12), 'Q1', '_seasonal_qtr 2018-12';
    is _seasonal_qtr(2019,01), 'Q1', '_seasonal_qtr 2019-01';
    is _seasonal_qtr(2019,02), 'Q1', '_seasonal_qtr 2019-02';
    is _seasonal_qtr(2019,03), 'Q2', '_seasonal_qtr 2019-03';

    is _seasonal_year(2018,11), '2017', '_seasonal_year 2018-11';
    is _seasonal_year(2018,12), '2018', '_seasonal_year 2018-12';
    is _seasonal_year(2019,01), '2018', '_seasonal_year 2019-01';
    is _seasonal_year(2019,02), '2018', '_seasonal_year 2019-02';
    is _seasonal_year(2019,03), '2018', '_seasonal_year 2019-03';

    is _seasonal_decade(2009,11), '2000', '_seasonal_decade 2009-11';
    is _seasonal_decade(2009,12), '2010', '_seasonal_decade 2009-12';
    is _seasonal_decade(2010,01), '2010', '_seasonal_decade 2010-01';
};

subtest '_get_kml_color' => sub {
    my @good_colors = qw( blue green azure purple red white yellow);
    foreach my $c (@good_colors) {
        ok _get_kml_color($c), '_get_kml_color ' . $c;
    }
    my @abbrev_good_colors = qw( b g a p r w y);
    foreach my $c (@abbrev_good_colors) {
        ok _get_kml_color($c), '_get_kml_color abbreviated ' . $c;
    }

    is _get_kml_color('x'), undef, '_get_kml_color "x" returned undef';
};

subtest '_match_location' => sub {
    my ($stn_id, $stn_name, $pattern);

    ($stn_id, $stn_name, $pattern) = ('CA006105887', 'irrelevant', 'CA006105887');
    is _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_id matched';

    ($stn_id, $stn_name, $pattern) = ('CA006105887', 'irrelevant', 'xxx');
    isnt _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_id not matched';

    ($stn_id, $stn_name, $pattern) = ('', 'OTTAWA', 'OTTAWA');
    is _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_name matched';

    ($stn_id, $stn_name, $pattern) = ('', 'OTTAWA', 'zzz');
    isnt _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_name not matched';

    ($stn_id, $stn_name, $pattern) = ('CA006105976', 'irrelevant', 'CA006105887,CA006105976,CA006106003');
    is _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_id found in list';

    ($stn_id, $stn_name, $pattern) = ('US001234567', 'irrelevant', 'CA006105887,CA006105976,CA006106003');
    isnt _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: stn_id not found in list';

    ($stn_id, $stn_name, $pattern) = ('', 'WEST VANCOUVER OTTAWA', 'WEST.*OTTAWA');
    is _match_location($stn_id, $stn_name, $pattern), $TRUE, '_match_location: pattern WEST.*OTTAWA';

};

subtest '_parse_missing_text' => sub {
    my %got;
    my $months_aref;
    my $mmdd_aref;

    my $_month_names = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct';
    ($months_aref, $mmdd_aref) = _parse_missing_text($_month_names);

    is_deeply $months_aref, [1..10], '_parse_missing_text: month names Jan-Oct - 1st retval';
    is_deeply $mmdd_aref,   [],      '_parse_missing_text: month names Jan-Oct - 2nd retval';

    my $day_ranges = 'May[2] Oct[3,11] Nov[1] Dec[2,5]';

    ($months_aref, $mmdd_aref) = _parse_missing_text($day_ranges);

    my $expected = [
        [  5,  2 ],
        [ 10,  3 ],
        [ 10, 11 ],
        [ 11,  1 ],
        [ 12,  2 ],
        [ 12,  5 ],
    ];

    is_deeply $months_aref, [],         '_parse_missing_text: ' . $day_ranges . ' - 1st retval';
    is_deeply $mmdd_aref,   $expected,  '_parse_missing_text: ' . $day_ranges . ' - 2nd retval';

};

subtest '_month_names' => sub {
    my @mm = (1..12);
    my @got = _month_names(@mm);
    my @expected = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    is_deeply \@got, \@expected, '_month_names for 1..12';
    is _month_names('alpha'), '???', '_month_names for invalid mm - string "alpha"';
    is _month_names(0), '???', '_month_names for invalid mm - zero (0)';
    is _month_names(13), '???', '_month_names for invalid mm - thirteen (13)';

    @mm = ();
    is scalar _month_names(@mm), 0, '_month_names() returns ()';

};

subtest '_memsize' => sub {
    my %h;
    map { $h{$_} = '#' x $_ } (1..1000);
    my $s = _memsize( \%h, $TRUE);
    like $s, qr{ \[ \d+ , \d+ \] }xms, '_memsize';
};

subtest '_qflags_as_string' => sub {
    my $qflags_href = {
        N => 9,
        I => 1,
        S => 5,
    };

    my $s = _qflags_as_string( $qflags_href );
    is $s, 'I:1, N:9, S:5', '_qflags_as_string with hashref';

    $s = _qflags_as_string( undef );
    is $s, $EMPTY, '_qflags_as_string with undef';

    $s = _qflags_as_string( {}  );
    is $s, $EMPTY, '_qflags_as_string with empty hash';
};

