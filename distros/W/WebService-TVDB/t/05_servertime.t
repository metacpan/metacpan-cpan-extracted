#!perl

use strict;
use warnings;

use Test::More tests => 3;

use XML::Simple qw(:strict);
use FindBin qw($Bin);

BEGIN { use_ok('WebService::TVDB::Servertime'); }

my $servertime;       # WebService::TVDB::Servertime object
my $previous_time;    # previous server time

# get a new object
$servertime = WebService::TVDB::Servertime->new();
isa_ok( $servertime, 'WebService::TVDB::Servertime' );

# test getting a mirror from XML
$servertime->{parsed_xml} = XML::Simple::XMLin(
    "$Bin/resources/servertime.xml",
    ForceArray => 0,
    KeyAttr    => []
);
$previous_time = $servertime->get_servertime();
is( $previous_time, '1329830659' );

# live test, fetching from http://thetvdb.com
#$servertime->fetch_servertime();
#$previous_time = $servertime->get_servertime();
#like( $previous_time, qr/^\d+$/ );
