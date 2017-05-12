#!perl -T

use Test::More tests => 6;

use_ok( 'WWW::Session' ) || print "Bail out!\n";
use_ok( 'WWW::Session::Storage::File' ) || print "Bail out!\n";
use_ok( 'WWW::Session::Storage::MySQL' ) || print "Bail out!\n";

my $have_memcache = 1;
eval "use Cache::Memcached";
$have_memcache = 0 if $@;

SKIP: {
	skip "Cache::Memcached is not installed",1 unless $have_memcache;
	use_ok( 'WWW::Session::Storage::Memcached' );
}

use_ok( 'WWW::Session::Serialization::JSON' ) || print "Bail out!\n";
use_ok( 'WWW::Session::Serialization::Storable' ) || print "Bail out!\n";

note( "Testing WWW::Session $WWW::Session::VERSION, Perl $], $^X" );
