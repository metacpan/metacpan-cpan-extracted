# Test suite for GHCN

use strict;
use warnings;
use v5.18;

use Test::More tests => 1;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::CacheURI;

my $cachedir = $FindBin::Bin . '/ghcn_cache';

my $clean = 1
    if grep { 'clean' eq lc $_ } @ARGV;;

my $errors_aref;

# Clean out the cache if this script is run with command line argument
# 'clean'.  To invoke this option when running 'prove', use the
# arisdottle; i.e. prove :: clean
#
# Until these cache files can be made platform portable, we'll also
# clean the cache when we are not on Windows x64.
#
if ( $clean ) {
    if (-e $cachedir) {
        my $cache = Weather::GHCN::CacheURI->new($cachedir, "never");
        my @errors = $cache->clean_cache;
        is_deeply \@errors, [], 'removed contents of cache ' . $cachedir;
    } else {
        ok 1, "*I* cache folder doesn't exist yet: " . $cachedir;
    }
} else {
    ok 1, 'using cache folder ' . $cachedir;
}