#!perl -T

use Test::More tests => 3;

use_ok( 'WWW::Session' ) || print "Bail out!\n";
use_ok( 'WWW::Session::Storage::Redis' ) || print "Bail out!\n";

my $have_redis = 1;
eval "use Cache::Redis";
$have_redis = 0 if $@;

SKIP: {
	skip "Cache::Redis is not installed",1 unless $have_redis;
	use_ok( 'WWW::Session::Storage::Redis' );
}

note( "Testing WWW::Session::Storage::Redis $WWW::Session::Storage::Redis::VERSION, Perl $], $^X" );
