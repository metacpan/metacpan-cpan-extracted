#!perl

use strict;
use warnings;

use Test::More tests => 2;
use FindBin qw($Bin);

use WebService::TVDB::Util ':all';

my $string   = '|Comedy|Action|';
my @expected = qw(Comedy Action);
is_deeply( pipes_to_array($string), \@expected, 'pipes to array' );

# test slurping the api_key from a file
my $api_key = get_api_key_from_file("$Bin/resources/tvdb");
is( $api_key, 'ABC123' );
