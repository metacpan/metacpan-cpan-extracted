#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('WebService::TVDB::Actor'); }

my $actor;    # WebService::TVDB::Actor object

# empty new
$actor = WebService::TVDB::Actor->new();
isa_ok( $actor, 'WebService::TVDB::Actor' );
