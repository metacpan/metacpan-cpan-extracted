#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'WWW::Session' ) || print "Bail out!\n";
use_ok( 'WWW::Session::Storage::Redis' ) || print "Bail out!\n";

note( "Testing WWW::Session::Storage::Redis $WWW::Session::Storage::Redis::VERSION, Perl $], $^X" );
