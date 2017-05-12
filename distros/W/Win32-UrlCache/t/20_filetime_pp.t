use strict;
use warnings;
use Test::More qw( no_plan );
use Win32::UrlCache::FileTimePP;

ok( "".filetime( '0x809f9d637b90c701' ) eq '2007-05-07T07:43:23' );
ok( "".filetime( 'Äüùc{ê«' ) eq '2007-05-07T07:43:23' );
