# Test suite for GHCN

# Notes about this test file:
#
# StationTable is a fairly large class with a lot of public and private
# methods.  Testing these independently is almost impossible, because
# they depend on the state of the object, which in turn is determined
# by the calling sequence.  The general callubg pattern can be seen in
# the example provided in the POD synopsis for Weather::GHCN::StationTable.
#
# The general sequence to use is:
#    new
#    tstats (if you want to collect timing statistics)
#    set_options
#    load_stations
#
# This gets you station metadata, but no actual weather data.  You can
# call get_stations now, or wait until later after you've called
# load_data.  You can also call export_kml after this point.
#
# Next call load_data to obtain weather data.  The remaining methods
# will be safe to call after that.  In particular if you want to
# get data aggregated by day, month or year you'll need to call
# summarize_data and then get_summary_data (and the report option must
# be one of daily, weekly or monthly).
#
# Because this script loads station metadata and data, it relies on
# data cached in t\ghcn_cache to (a) improve performance by avoiding
# the overhead of an URI::Fetch call across the network, and (b) so
# that the data is stable for testing purposes.  The -nonetwork option
# is set to constant $NONETWORK, which is set to 1, to force URI::Fetch
# to only fetch from the cache.  If any pages are missing, URI::Fetch
# will return undef and test cases will fail.  For this reason, it's
# best not to fiddle with the $config_options cache options.
#
# You can change options by calling set_options again, and you can even
# skip calling load_stations if the changes you made to options are
# only data-related.  For example, if you add a -fmonth filter or
# change the -range, you just need to call load_data again.  But,
# if you change criterie that would affect the set of stations you
# are working on, like -location, then you'll need to call load_stations
# before load_data.  When in doubt, start over with a new object.
# See subtest reload_with_new_options for an example.


use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::StationTable;
package Weather::GHCN::StationTable;

use Test::More tests => 16;
use Test::Exception;

use Const::Fast;
use File::Temp;
use File::Spec;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';
const my $NL     => qq(\n);

const my $CONFIG_FILE => $FindBin::Bin . '/ghcn_fetch.yaml';

my $cachedir = $FindBin::Bin . '/ghcn_cache/ghcn';

my $Nonetwork;       # control caching

if (not -d $cachedir) {
    # no cache folder, so allow server access so the cache will be created
    # note that it may take some time to fetch the pages
    # expect the cache to be about 45 Mb
    $Nonetwork = 0;
    warn "creating or refreshing cache: $cachedir\n";
} else {
    # do not contact the server
    $Nonetwork = 1;
    warn "using cache: $cachedir\n";
}

my $ghcn;
my $stn_href;
my $Opt;

# get config options from the test options file instead of from
# the default, which is $HOME/.ghcn_fetch.yaml
my $cache_for_testing = {
    cache => {
      root => $FindBin::Bin . '/ghcn_cache',
      namespace => 'ghcn',
    }
};

# skip to START_TESTING if there's a non-zero command line arg
# uncoverable branch true
# uncoverable condition left
# uncoverable condition true
our $DEBUG = shift @ARGV // 0;
# uncoverable branch true
goto START_TESTING if $DEBUG;

subtest 'set_options with config_options' => sub {
    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'yow',
                nonetwork   => $Nonetwork,
            },
            config_options => {
                aliases => {
                    yow => 'CA006106000,CA006106001',
                }
            }
        );
    like ref $opt, qr/ \A Hash::Wrap::Class /xms, 'set_options returned a Hash::Wrap';
    is @errors, 0, 'set_options returned no errors';

    ok $ghcn->opt_href->{location} eq 'CA006106000,CA006106001', 'alias yow from config_options ($ghcn->opt_href->{location})';
    ok $opt->location eq 'CA006106000,CA006106001', 'alias yow from config_options ($opt->location)';
};

subtest 'set_options with config_file' => sub {
    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'yow',
                nonetwork   => $Nonetwork,
            },
            config_file => $CONFIG_FILE,
        );

    is @errors, 0, 'set_options returned no errors';

    ok $ghcn->config_file, 'config_file accessor';
    ok $ghcn->opt_href->{location} eq 'CA006106000,CA006106001', 'alias yow from config_options ($ghcn->opt_href->{location})';
    ok $opt->location eq 'CA006106000,CA006106001', 'alias yow from config_options ($opt->location)';
};

subtest "station list (-loc ZZZZZ)" => sub {
    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'ZZZZZ',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 0, 'no stations found';
};

subtest 'station list (-report "")' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                country     => 'US',
                state       => 'NY',
                location    => 'New York',
                active      => '1900-1910',
                report      => '',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    like ref $opt, qr/ \A Hash::Wrap::Class /xms, 'set_options returned a Hash::Wrap';

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 2, 'kept=>1 two stations kept';

    $stn_href = $ghcn->load_stations;
    @kept = $ghcn->get_stations( list => 1, kept => undef, no_header => 1 );
    is @kept, 11, 'kept=>undef eleven stations kept';

    $stn_href = $ghcn->load_stations;
    @kept = $ghcn->get_stations( list => 1, kept => 0, no_header => 1 );
    is @kept, 9, 'kept=>0 nine stations kept';

    my @kml = $ghcn->export_kml( list => 1 );
    my $count = grep { m{ kml | NEW \s YORK \s WB }xms } @kml;
    # 5 is the number of times NEW YORK WB occurs in the output
    is $count, 5, 'export_kml output looks good';
};

subtest 'station-level data (-report id)' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                active      => '',
                report      => 'id',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 1, 'one station kept';

    my @rows;

    my $hdr_text = $ghcn->get_header();
    ok length($hdr_text) > 0, 'get_header returned text';

    my @hdr = $ghcn->get_header( list => 1);
    is @hdr, 15, 'get_header returned 15 header columns';

    $ghcn->load_data(
        # set a callback routine for capturing data rows when report => 'id'
        row_sub => sub { push @rows, $_[0] },
    );
    is @rows, 365, '365 rows returned for year 1900';
};

# for test coverage
subtest 'field accessors' => sub {
    ok $ghcn->opt_obj,              'opt_obj';
    ok $ghcn->opt_href,             'opt_href';
    # config_file will be tested in subtest "set_options with config_file"
    ok $ghcn->config_href,          'config_href';
    ok $ghcn->stn_count,            'stn_count';
    ok $ghcn->stn_selected_count,   'stn_selected_count';
    ok $ghcn->stn_filtered_count,   'stn_filtered_count';
    ok $ghcn->missing_href,         'missing_href';
};

subtest 'daily data (-report daily)' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                report      => 'daily',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;

    $ghcn->load_data();

    $ghcn->summarize_data();
    my @rows = $ghcn->get_summary_data( list => 1 );
    is @rows, 365, '365 rows returned for year 1900';
};

subtest 'monthly data (-report monthly)' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                report      => 'monthly',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;

    my @hdr = $ghcn->get_header( list => 1);
    is @hdr, 9, '9 header columns';

    $ghcn->load_data();

    $ghcn->summarize_data();
    my @rows = $ghcn->get_summary_data( list => 1 );
    is @rows, 12, '12 rows returned for year 1900';
};

subtest 'yearly data (-report yearly)' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                report      => 'yearly',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;

    my @hdr = $ghcn->get_header( list => 1);
    is @hdr, 5, '5 header columns';

    $ghcn->load_data();

    $ghcn->summarize_data();
    my @rows = $ghcn->get_summary_data( list => 1 );
    is @rows, 1, '1 rows returned for year 1900';
};


subtest 'epilog' => sub {
    my @footer = $ghcn->get_footer( list => 1 );
    ok @footer, 'footer list returned';
    like $footer[0], qr/Notes/, 'footer looks good';

    my $footer = $ghcn->get_footer( list => 0 );
    like $footer, qr/Notes/, 'footer line was returned';

    my $fc_href = $ghcn->flag_counts;
    is ref $fc_href, 'HASH', 'flag_counts returned a hash';
    is keys $fc_href->%*, 3, 'flag_counts hash has 3 keys';

    my $flag_stats_text = $ghcn->get_flag_statistics( list => 0 );
    ok $flag_stats_text, 'flag stats returned text';
    my @flag_stats = split($NL, $flag_stats_text);
    is @flag_stats, 3, 'flag stats returned 3 lines';
    like $flag_stats[0], qr/Values/, 'flag stats header line';
    like $flag_stats[1], qr/TMAX/,   'flag stats TMAX line';
    like $flag_stats[2], qr/TMIN/,   'flag stats TMIN lines';


    @flag_stats = $ghcn->get_flag_statistics( list => 1 );
    is @flag_stats, 3, 'flag stats returned 3 entries';
    is $flag_stats[0][0], 'Values', 'flag stats header row';
    is $flag_stats[1][0], 'TMAX',   'flag stats TMAX row';
    is $flag_stats[2][0], 'TMIN',   'flag stats TMIN row';


    my @opt_list = $ghcn->get_options( list => 1 );
    ok @opt_list > 0, 'get_options list output looks good';

    my $opt_string = $ghcn->get_options;
    like $opt_string, qr/baseline/, 'get_options string looks good';

    my $hs_text = $ghcn->get_hash_stats( list => 0 );
    is split($NL, $hs_text), 6, 'get_hash_stats returned 6 lines';

    my @hs = $ghcn->get_hash_stats( list => 1 );
    is @hs, 6, 'get_hash_stats returned 2 headers plus 4 entries';

    @hs = $ghcn->get_hash_stats( list => 1, no_header => 1 );
    is @hs, 4, 'get_hash_stats no_header returned 4 entries';

    isa_ok $ghcn->tstats, 'Weather::GHCN::TimingStats';

    my $ts = $ghcn->get_timing_stats( list => 0 );
    is split($NL, $ts), 12, 'get_timing_stats returned 12 lines';

    my @ts = $ghcn->get_timing_stats( list => 1 );
    is @ts, 12, 'get_timing_stats returned 12 entries';
};

subtest 'missing_data' => sub {
    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976,CA006105978', # OTTAWA CDA & CDA RCS
                range       => '2017-2018',
                report      => 'yearly',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options return no errors';

    my $stn_href = $ghcn->load_stations;

    $ghcn->load_data();

    $ghcn->summarize_data();

    ok $ghcn->has_missing_data, 'has_missing_data returned true';
    my $missing_text = $ghcn->get_missing_data_ranges( list => 0 );
    like $missing_text, qr/Missing year,/, 'get_missing_data_ranges text looks good';

    my @missing_list = $ghcn->get_missing_data_ranges( list => 1 );
    is @missing_list, 5, 'get_missing_data_ranges returned 5 rows';

    my @notes = $ghcn->get_station_note_list;
    ok @notes, 'get_station_note_list returned notes';
    like $notes[0], qr/54 .*? station \s missing/xms, 'get_station_note_listnote looks good';

    my $missing = $ghcn->get_missing_rows( list => 0 );
    is split($NL, $missing), 49, 'get_missing_rows generated 49 missing rows';
    like $missing, qr/\A 2017 \t 2 \t 8/xms, 'get_missing_rows text returned looks good';

    my @missing_rows = $ghcn->get_missing_rows( list => 1 );
    is @missing_rows, 49, 'get_missing_rows generated 49 missing rows';

    # now try the case were there is no missing data
    $ghcn = Weather::GHCN::StationTable->new;

    ($opt, @errors) = $ghcn->set_options(
            user_options => {
                location    => 'CA006105976', # OTTAWA CDA & CDA RCS
                range       => '2014-2014',
                report      => 'yearly',
                quality     => 0,
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options return no errors';
    $stn_href = $ghcn->load_stations;
    $ghcn->load_data();
    $ghcn->summarize_data();
};

subtest 'reload with new options' => sub {

    # tests whether we can do set_options a second time, after
    # load_stations and load_data, with new options and get new
    # results and without throwing an error.

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my $uo_href = {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                active      => '',
                report      => 'id',
                nonetwork   => $Nonetwork,
            };

    my ($opt, @errors) = $ghcn->set_options(
            user_options => $uo_href,
            config_options => $cache_for_testing,
        );
    ok $opt, '------- set_options 1: -loc CA006105976 -range 1900-1900 -active "" -report id';

    is @errors, 0, 'set_options return no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 1, 'one station kept';

    my @rows;

    my @hdr = $ghcn->get_header( list => 1);
    is @hdr, 15, '15 header columns';

    $ghcn->load_data(
        # set a callback routine for capturing data rows when report => 'id'
        row_sub => sub { push @rows, $_[0] },
    );
    ok @rows, '------- load_data 1';
    is @rows, 365, '365 rows returned for year 1900';

    my %h = $ghcn->datarow_as_hash( $rows[0] );
    is $h{'StationId'}, 'CA006105976', 'datarow_as_hash seems ok';

    $uo_href->{fmonth}  = 1;
    $uo_href->{fday}    = '15-16';
    $uo_href->{tavg}    = $TRUE;
    $uo_href->{precip}  = $TRUE;

    # Normally, quality defaults to 90%.  Any station that doesn't have
    # at least 90% data coverage within the range will be dropped from
    # the output.  Since fmonth = 1 and fday = 15-16 we'll only have
    # 2 days for the range of 1900-1900.  That's just 0.5% so unless
    # we lower the quality threshold to 0 there won't be any data output.
    $uo_href->{quality} = 0;

    ($opt, @errors) = $ghcn->set_options(
            user_options => $uo_href,
            config_options => $cache_for_testing,
        );
    ok $opt, '------- set_options 2: adding -fmonth 1 -fday 15-16 -tavg -precip -quality 0';

    is @errors, 0, 'set_options return no errors';

    @hdr = $ghcn->get_header( list => 1);
    is @hdr, 19, '19 header columns';

    my $count = grep { m{ PRCP | SNOW | SNWD }xms } @hdr;
    is $count, 3, 'PRCP SNOW SNWD included in header';

    @rows = ();
    $ghcn->load_data(
        # set a callback routine for capturing data rows when report => 'id'
        row_sub => sub { push @rows, $_[0] },
    );
    ok @rows, '------- load_data 2';
    is @rows, 2, 'fmonth 1 fday 15-16 returned 2 rows';

    $uo_href = {
                location    => 'CA006105976', # OTTAWA CDA
                range       => '1900-1900',
                active      => '',
                report      => 'yearly',
                precip      => 1,
                nonetwork   => $Nonetwork,
            };

    ($opt, @errors) = $ghcn->set_options(
            user_options => $uo_href,
            config_options => $cache_for_testing,
        );
    $ghcn->load_data();
    $ghcn->summarize_data();
    @rows = $ghcn->get_summary_data( list => 1 );
    ok @rows, '------- load_data 3';
    is @rows, 1, '-report yearly -precip';

};

subtest "station list (-kml '<tempfile>')" => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my $tmpdir = File::Spec->tmpdir();
    my $fh = File::Temp->new(
        TEMPLATE => '__temp_XXXXX',
        DIR => $tmpdir,
        SUFFIX => '.kml',
        UNLINK => 1,
    );
    my $kmlfile = $fh->filename;

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                country     => 'US',
                state       => 'NY',
                location    => 'New York',
                active      => '1900-1910',
                report      => '',
                kml         => $kmlfile,
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    like ref $opt, qr/ \A Hash::Wrap::Class /xms, 'set_options returned a Hash::Wrap';

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 2, 'two stations kept';

    $ghcn->export_kml();

    is -r $kmlfile, $TRUE, 'export_kml file is readable';
    ok -s $kmlfile > 0, ,  'export_kml file has non-zero size';
};


subtest 'station list (-gps "40.7789 -73.9692" -radius 12)' => sub {
    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                gps         => '40.7789 -73.9692',
                radius      => 12,
                active      => '1900-1910',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );

    is @kept, 3, '3 stations (active 1900-1910) found within 12 km ofNYC Central Park tower';
    ok grep { m{ BRONX }xms } @kept, 'BRONX station found';

};

subtest 'station-level data (-report id)' => sub {

    $ghcn = new_ok 'Weather::GHCN::StationTable';

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                anomalies   => 1,
                location    => 'CA006105976', # OTTAWA CDA
                range       => '2016-2019',
                baseline    => '2016-2017',
                fmonth      => 2,
                fday        => '2-3',
                report      => 'id',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 1, 'one station kept';

    my $hdr_text = $ghcn->get_header();
    ok length($hdr_text) > 0, 'get_header returned text';

    my @hdr = $ghcn->get_header( list => 1);
    is @hdr, 18, 'get_header returned 18 header columns';

    my $count = grep { m{ A_TMAX | A_TMIN | A_Tavg }xms } @hdr;
    is $count, 3, 'A_TMAX A_TMIN A_Tavg included in header';

    my %data;
    $ghcn->load_data(
        # turn the data into a hash of hashes, where the key
        # is the date of the entry in yyyy-mm-dd format and the
        # value is a hash of column_name/data_value pairs.
        # We have only selected a single station, so we don't have
        # to worry about more than one row per date.
        row_sub => sub {
            my ($row_aref) = @_;
            my %h = ( $ghcn->datarow_as_hash ( $row_aref ) );
            my $key = sprintf '%4d-%02d-%02d', $h{Year}, $h{Month}, $h{Day};
            $data{$key} = \%h
        },
    );

    # check the anomalies calculations
    my %expected = (
        #               A_TMAX  A_TMIN    A_Tavg
        '2016-02-02' => [  3.15 ,   3    ,   3.08 ],
        '2017-02-02' => [ -3.15 ,  -3    ,  -3.08 ],
        '2018-02-02' => [ -12.15,  -7    ,  -9.57 ],
        '2019-02-02' => [ -4.15 ,  -9    ,  -6.58 ],
        '2016-02-03' => [  6.05 ,   1.95 ,   4    ],
        '2017-02-03' => [ -6.05 ,  -1.95 ,  -4    ],
        '2018-02-03' => [ -3.05 ,  -12.95,  -8    ],
        '2019-02-03' => [ -9.55 ,  -4.95 ,  -7.25 ],
    );

    foreach my $ymd (sort keys %data) {
        # do a fuzzy comparison between calues in the table above and
        # and those obtained from the data because an equality comparison
        # between floats fails occasionally (especially on Unix)
        ok abs( ($data{$ymd}{A_TMAX}+0) - ($expected{$ymd}->[0]+0) ) < 0.01, "$ymd A_TMAX correct anomaly calc";
        ok abs( ($data{$ymd}{A_TMIN}+0) - ($expected{$ymd}->[1]+0) ) < 0.01, "$ymd A_TMIN correct anomaly calc";
        ok abs( ($data{$ymd}{A_Tavg}+0) - ($expected{$ymd}->[2]+0) ) < 0.01, "$ymd A_Tavg correct anomaly calc";
    }
};


subtest "station list (-partial)" => sub {
    $ghcn = Weather::GHCN::StationTable->new;

    my ($opt, @errors) = $ghcn->set_options(
            user_options => {
                country     => 'US',
                state       => 'NY',
                active      => '1870-1880',
                partial     => 1,
                report      => '',
                nonetwork   => $Nonetwork,
            },
            config_options => $cache_for_testing,
        );

    is @errors, 0, 'set_options returned no errors';

    my $stn_href = $ghcn->load_stations;
    my @kept = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
    is @kept, 3, '3 stations found for -active 1870-1880 -partial';
};

START_TESTING: