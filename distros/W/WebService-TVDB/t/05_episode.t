#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('WebService::TVDB::Episode'); }

my $episode;    # WebService::TVDB::Episode object

# empty new
$episode = WebService::TVDB::Episode->new( FirstAired => '1992-10-06' );
isa_ok( $episode, 'WebService::TVDB::Episode' );
is( $episode->year, '1992', 'episode year' );
