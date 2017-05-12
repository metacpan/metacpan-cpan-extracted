#!/usr/bin/perl
# a command interface to Net::LastFMAPI
use strict;
use warnings;
use v5.10;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;
use JSON::XS;
use YAML::Syck;

die "usage: $0 user.whatEver something=nothing nothing=Some Things etc=etc\n" unless @ARGV;
if (exists $Net::LastFMAPI::methods->{lc($ARGV[0])}) {
    my $method = shift @ARGV;
    my %params;
    my $args = "@ARGV";
    while ($args =~ m{\G *(\S+)=(.*?)(?= *\S+=|$)}g) {
        $params{$1} = $2;
    }
    my $res = lastfm($method, %params);
    if (ref $res eq "HASH") {
        $res = Dump($res);
    }
    say $res
}
else {
    die "Bad command or file name.\n";
}
