#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('WebService::TVDB::Banner'); }

my $banner;    # WebService::TVDB::Banner object

# empty new
$banner = WebService::TVDB::Banner->new();
isa_ok( $banner, 'WebService::TVDB::Banner' );
