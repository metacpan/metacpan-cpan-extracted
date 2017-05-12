#!perl

use strict;
use warnings;

use Test::More tests => 101;

use FindBin qw($Bin);
use XML::Simple qw(:strict);

BEGIN { use_ok('WebService::TVDB::Series'); }

my $series;    # WebService::TVDB::Series object
my $xml;       # parsed xml data

### empty new
$series = WebService::TVDB::Series->new();
isa_ok( $series, 'WebService::TVDB::Series' );

### parse actors.xml
$xml = XML::Simple::XMLin(
    "$Bin/resources/zip/actors.xml",
    ForceArray => ['Actor'],
    KeyAttr    => 'Actor'
);
$series->_parse_actors($xml);
my $actors = $series->actors;
is( @$actors, 7, '7 actors' );

for ( @{$actors} ) {
    isa_ok( $_, 'WebService::TVDB::Actor' );
}

# check order
my $actor = @{$actors}[0];
is( $actor->id,   44200 );
is( $actor->Name, 'Caroline Quentin' );

### parse banners.xml
$xml = XML::Simple::XMLin(
    "$Bin/resources/zip/banners.xml",
    ForceArray => ['Banner'],
    KeyAttr    => 'Banner'
);
$series->_parse_banners($xml);
my $banners = $series->banners;
is( @$banners, 20, '20 banners' );

for ( @{$banners} ) {
    isa_ok( $_, 'WebService::TVDB::Banner' );
}

# check order
my $banner = @{$banners}[0];
is( $banner->id,         22614 );
is( $banner->BannerType, 'fanart' );
is( $banner->url, 'http://thetvdb.com/banners/fanart/original/76213-1.jpg' );

### parse <language.xml>
$xml = XML::Simple::XMLin(
    "$Bin/resources/zip/en.xml",
    ForceArray => ['Data'],
    KeyAttr    => 'Data'
);
$series->_parse_series_data($xml);

is( $series->Status,      'Ended' );
is( $series->Rating,      '8.4' );                # it's pretty good!
is( $series->Genre->[0],  'Comedy' );
is( $series->Actors->[0], 'Caroline Quentin' );

my $episodes = $series->episodes;
is( @$episodes, 57, '57 episodes' );
for ( @{$episodes} ) {
    isa_ok( $_, 'WebService::TVDB::Episode' );
}

# check order
my $episode = @{$episodes}[0];
is( $episode->id,          342429 );
is( $episode->EpisodeName, 'Children in Need Special' );

$episode = $series->get_episode( 6, 1 );
is( $episode->EpisodeName, 'Stag Night', 'episode title' );
