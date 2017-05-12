#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('WebService::IMDBAPI::Result'); }

my $result;    # WebService::IMDBAPI::Result object

# empty new
$result = WebService::IMDBAPI::Result->new();
isa_ok( $result, 'WebService::IMDBAPI::Result' );
