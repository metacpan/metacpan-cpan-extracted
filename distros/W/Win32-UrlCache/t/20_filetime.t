use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'This test is valid only under Win32' if $^O ne 'MSWin32';
}

plan tests => 2;
use Win32::UrlCache::FileTime;

ok( "".filetime( '0x809f9d637b90c701' ) eq '2007-05-07 07:43:23' );
ok( "".filetime( 'Äüùc{ê«' ) eq '2007-05-07 07:43:23' );
