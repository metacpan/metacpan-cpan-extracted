#!/usr/bin/perl
# submit one scrobble, pass an argument like: Artist Name - Track Title 
use strict;
use warnings;
use v5.10;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;

my $track = "@ARGV";
unless ($track) {
    say "Enter thy track like Artist - Title";
    $track = <STDIN>;
}
say "...";
my @track = split /\s*-\s*/, $track;
my %params;
$params{track} = pop @track;
$params{artist} = shift @track;
$params{album} = shift @track if @track;
my $res = lastfm(
    "track.scrobble",
    %params,
    format => "xml",
    timestamp => scalar(time()),
);
unless ($res =~ /accepted="1"/) {
    die "For fucks sake: $res";
}
else {
    say "Good good.";
}
