#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Test::More 'no_plan';
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;
use JSON::XS;
use Storable 'dclone';

$Net::LastFMAPI::session_key = '32d3825593e0636a8bd59343911569ba';

my $actual_api_key = $Net::LastFMAPI::api_key;
lastfm_config(
    api_key => "dfab9b1c7357c55028c84b9a8fb68881",
);
is($Net::LastFMAPI::api_key, "dfab9b1c7357c55028c84b9a8fb68881", "config item set");
eval { lastfm_config(invalid => "blah") };
like($@, qr{^invalid config items: invalid}, "invalid config item");
$Net::LastFMAPI::api_key = $actual_api_key; 
$@ = "";

eval {
lastfm(
    "track.scrobble",
    ({
        artist => "Robbie Basho",
        track => "Wounded Knee Soliloquy",
        timestamp => time() - 30,
    }) x 51,
)
};
like $@, qr/^too multitudinous \(limit 50\)/, "too multitudinously scrobbling";

our @uaaction = ();
our $response;
our $uaaction = sub {
    push @uaaction, dclone([@_]);
    return YouAye->new(content => ($response || encode_json({ status => "ok" })));
};
package YouAye;
sub new {
    shift;
    return bless {@_}, __PACKAGE__;
}
sub get {
    shift;
    $main::uaaction->("get", @_);
}
sub post {
    shift;
    $main::uaaction->("post", @_);
}
sub decoded_content {
    shift->{content};
}
sub is_success { 1 }
package main;
$Net::LastFMAPI::ua = YouAye->new();

lastfm(
    "track.scrobble",
    ({
        artist => "Robbie Basho",
        track => "Wounded Knee Soliloquy",
        timestamp => 1320224836 - 30,
    }) x 4,
);

is($uaaction[-1]->[0], "post", "scrobbles POSTed");
is($uaaction[-1]->[3]->{api_sig}, "30c3b59dc26c6d67cdb3fef190ea47ba", ", request signed");




$response = <<'';
{"user":{"country":"NZ","registered":{"#text":"2006-03-18 22:44","unixtime":"1142678658"},"subscriber":"0","lang":"en","name":"298563498653468","bootstrap":"0","age":"","image":[{"#text":"http://userserve-ak.last.fm/serve/34/5906980.jpg","size":"small"},{"#text":"http://userserve-ak.last.fm/serve/64/5906980.jpg","size":"medium"},{"#text":"http://userserve-ak.last.fm/serve/126/5906980.jpg","size":"large"},{"#text":"http://userserve-ak.last.fm/serve/252/5906980.jpg","size":"extralarge"}],"playlists":"1","realname":"Steve","playcount":"79231","url":"http://www.last.fm/user/298563498653468","type":"user","id":"3466668","gender":"m"}}

my $res = lastfm("user.getInfo");

is($uaaction[-1]->[0], "get", "user info GETed");
like($uaaction[-1]->[1], qr{format=json$}, "JSON requested");
is($uaaction[-1]->[1], 'http://ws.audioscrobbler.com/2.0/?api_key=dfab9b1c7357c55028c84b9a8fb68880&method=user.getinfo&sk=32d3825593e0636a8bd59343911569ba&format=json', "correct URI");
ok(ref $res eq "HASH", "decoded JSON returned");
is($res->{user}->{name}, "298563498653468", "username");
is($res->{user}->{country}, "NZ", "New Zealand!");
is($res->{user}->{image}->[-1]->{size}, "extralarge", "extralarge");





$response = <<XML;
<?xml version="1.0" encoding="utf-8"?>
<lfm status="ok">
<user>
    <name>tburny</name>
    <realname>Tobi &quot;The spam hunter&quot;</realname>
    <image size="small">http://userserve-ak.last.fm/serve/34/24152429.jpg</image>
    <image size="medium">http://userserve-ak.last.fm/serve/64/24152429.jpg</image>
    <image size="large">http://userserve-ak.last.fm/serve/126/24152429.jpg</image>
    <image size="extralarge">http://userserve-ak.last.fm/serve/252/24152429.jpg</image>
    <url>http://www.last.fm/user/tburny</url>
        
	<id>4932232</id>
		
    <country>DE</country>
    <age>22</age>
    <gender>m</gender>
    <subscriber>1</subscriber>
    <playcount>21077</playcount>
    <playlists>6</playlists>
    <bootstrap>0</bootstrap>
    <registered unixtime="1162113008">2006-10-29 21:10</registered>
	<type>moderator</type>
    
</user></lfm>
XML

my $res1 = lastfm("user.getInfo", user => "tburny", format => "xml");

is($uaaction[-1]->[0], "get", "user info GETed");
unlike($uaaction[-1]->[1], qr{format=xml}, "format=xml not requested");
is($uaaction[-1]->[1], 'http://ws.audioscrobbler.com/2.0/?api_key=dfab9b1c7357c55028c84b9a8fb68880&user=tburny&method=user.getinfo&sk=32d3825593e0636a8bd59343911569ba', "correct URI");
like($res1, qr{<lfm status="ok">}, "decoded JSON returned");
like($res1, qr{<name>tburny</name>}, "correct user");
