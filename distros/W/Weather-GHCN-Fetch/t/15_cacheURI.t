# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin qw($Bin);
use lib $Bin . '/../lib';

use Weather::GHCN::CacheURI;

use Test::More tests => 10;

use Const::Fast;
use Getopt::Long        qw( GetOptionsFromString );
use LWP::Simple;
use Path::Tiny;
use Test::Exception;
use Test::LongString;
use Time::Local;
use Time::Piece;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';
const my $SPACE  => q( );

# note that the test profile file does not start with a '.' because
# Dist::Zilla would ignore it when gathering files for the installation
# package.
const my $CONFIG_TEST_FILE => $Bin . '/ghcn_fetch.yaml';

use_ok 'Weather::GHCN::Options';

my $cache_uri_obj;
my $count;
my $expected;
my $got;
my @got;
my $key;
my $uri;
my $href;
my @files;
my $from_cache;
my $content;
my $my_content = 'some content';

sub create_tempdir_cache($template) {
    my $cachedir_obj = Path::Tiny->tempdir($template);
    my $cachedir = $cachedir_obj->stringify;
    return ($cachedir_obj, $cachedir);
}

my ($cachedir_obj, $cachedir) = create_tempdir_cache('ghcn_15_cacheURI_test_XXXXXX');

my @uri = (
    'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt',  # station list
    'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt', # station inventory
    #'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/CA006106001.dly', # OTTAWA INT'L
    'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/CA006105397.dly', # MOOSE CREEK ON 2018-2022 168K
);

# use the MOOSE CREEK daily weather file for testing because it's updated
# regularly but relatively small
my $test_uri = $uri[-1];
my @parts = split '/', $test_uri;
my $test_file = $parts[-1];
my ($stnid) = $test_file =~ m{ (\w+) [.]dly }xms;

# head returns ($content_type, $document_length, $modified_time, $expires, $server)
my $remote_mtime = ( head($test_uri) )[2];

ok $remote_mtime, "got $test_uri header";

# diag $cachedir;

subtest 'object instantiation' => sub {

    $cache_uri_obj = new_ok 'Weather::GHCN::CacheURI' => [ $cachedir, 'never' ];

    # Path::Tiny temporary directories are deleted when the object goes
    # out of scope.  By chaining tempdir() to ->stringify, we return
    # the path string for assignment and the Path::Tiny object is discarded
    # thus causing temporary directory it created to be deleted.  All
    # we are left with is the pathname for a directory that no longer exists.
    my $nonexistant_dir = Path::Tiny->tempdir( 'ghcn_15_cacheURI_test_XXXXXX' )->stringify;

    throws_ok { Weather::GHCN::CacheURI->new($nonexistant_dir, 'never') }
        qr/cache directory does not exist/,
        'new with nonexistant dir throws exception';

    throws_ok { Weather::GHCN::CacheURI->new($cachedir, 'bad refresh') }
        qr/invalid refresh option/,
        'new with invalid refresh argument';

    throws_ok { Weather::GHCN::CacheURI->new() }
        qr/Too few arguments/,
        'new without arguments';

};

subtest 'can_ok methods' => sub {
    can_ok $cache_uri_obj, 'clean_cache';
    can_ok $cache_uri_obj, 'clean_data_cache';
    can_ok $cache_uri_obj, 'clean_station_cache';
    can_ok $cache_uri_obj, 'fetch';
    can_ok $cache_uri_obj, 'load';
    can_ok $cache_uri_obj, 'store';
    can_ok $cache_uri_obj, 'remove';
};


subtest 'store, load, remove' => sub {
    $cache_uri_obj->store( 'temp1.txt', $my_content );

    @files = path($cachedir)->children;
    is @files, 1, 'store';

    my $got = $cache_uri_obj->load( 'temp1.txt' );
    is $got, $my_content, 'load';

    $cache_uri_obj->remove( 'temp1.txt' );

    @files = path($cachedir)->children;
    is @files, 0, 'remove';
};

subtest 'key methods' => sub {
    foreach my $uri (@uri) {
        $key = $cache_uri_obj->_uri_to_key( $uri );
        my @parts = split '/', $uri;
        is $key, $parts[-1], 'uri_to_key ' . $parts[-1];

        $got = $cache_uri_obj->_path_to_key( $uri );
        $expected = path($cachedir)->child($key)->stringify;
        is $got, $expected, 'path_to_key ' . $key;
    }
};

subtest 'fetch - refresh never' => sub {
    # fetch a daily page, but with an empty cache and refresh 'never' it will fail
    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    is $content, undef, 'fetch with refresh never and empty cache';
};

subtest 'fetch - refresh always' => sub {
    # instantiate a tempdir object, which will cause the old cache to be deleted
    ($cachedir_obj, $cachedir) = create_tempdir_cache('ghcn_15_cacheURI_test_XXXXXX');

    $cache_uri_obj = Weather::GHCN::CacheURI->new($cachedir, 'always');

    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok !$from_cache, "fetch $test_file from remote";
    like_string $content, qr/$stnid/, "fetch $test_file content";

    # now it's in the cache so let's try again
    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok $from_cache, "fetch $test_file from cache";
    like_string $content, qr/$stnid/, "fetch $test_file content";

    my $file_obj = path($cachedir)->child($test_file);
    ok $file_obj->is_file, "$test_file is in the cache";

    # now lets make the cached file older than the web page
    $got = $file_obj->touch($remote_mtime - 24*3600);
    ok $got, "$test_file is now a day older than the web page";

    # file is older now, so fetch should take it from the network not the cache
    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok !$from_cache, "fetch $test_file from network";
    like_string $content, qr/$stnid/, "fetch $test_file content";
};

subtest 'fetch - refresh yearly' => sub {
    # instantiate a tempdir object, which will cause the old cache to be deleted
    ($cachedir_obj, $cachedir) = create_tempdir_cache('ghcn_15_cacheURI_test_XXXXXX');

    $cache_uri_obj = Weather::GHCN::CacheURI->new($cachedir, 'yearly');

    # confirm it's not in the cache
    my $file_obj = path($cachedir)->child($test_file);
    ok !$file_obj->exists, "$test_file is not in the cache";

    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok $file_obj->exists, "$test_file is now in the cache";
    ok $from_cache != 1, "fetch $test_file from remote";
    like_string $content, qr/$stnid/, "fetch $test_file content";

    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok $from_cache, "fetch $test_file from cache";
    like_string $content, qr/$stnid/, "fetch $test_file content";

    my $yesterday = time - 24*3600;
    $file_obj->touch($yesterday);
    is $file_obj->stat->mtime, $yesterday, "$test_file is now 1 day older";

    # file is older now, but not old enough to cause a yearly refresh
    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok $from_cache, "fetch 1-day older $test_file from cache";
    ok $content, "fetch $test_file content";

    my $last_year = timelocal(0,0,0,1,12-1,localtime->year-1900-1);
    $file_obj->touch($last_year);
    is $file_obj->stat->mtime, $last_year, "$test_file dated last year";

    # file is old now, so fetch should take it from the network not the cache
    ($from_cache, $content) = $cache_uri_obj->fetch( $test_uri );
    ok !$from_cache, "fetch $test_file from network";
    ok $content, "fetch $test_file content";
};

subtest 'clean cache methods' => sub {
    my $cache_path_obj = path($cachedir);
    my $stn_file = 'ghcnd-stations.txt';
    my $inv_file = 'ghcnd-inventory.txt';
    # create these files
    $cache_path_obj->child($stn_file)->touch;
    $cache_path_obj->child($inv_file)->touch;

    ok $cache_path_obj->child($test_file)->exists, 'file ' . $test_file . ' is in the cache';
    $cache_uri_obj->clean_data_cache;
    ok !$cache_path_obj->child($test_file)->exists, 'file ' . $test_file . ' has been removed by clean_data_cache';
    @files = $cache_path_obj->children;
    ok @files == 2, 'only the data file was removed';

    $cache_uri_obj->clean_station_cache;
    @files = $cache_path_obj->children;
    ok @files == 0, 'station files were removed';

    # create these files
    $cache_path_obj->child($stn_file)->touch;
    $cache_path_obj->child($inv_file)->touch;
    $cache_path_obj->child($test_file)->touch;
    $cache_path_obj->child('not_a_cache_file.txt')->touch;

    $cache_uri_obj->clean_cache;
    @files = $cache_path_obj->children;
    like $files[0], qr/not_a_cache_file.txt/, 'station and daily files were removed, but not others';

};

# subtest 'create cache' => sub {};
