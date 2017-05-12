#!/usr/bin/perl
# submit scrobbles from a scrobbler.log
# format as per http://www.audioscrobbler.net/wiki/Portable_Player_Logging
use strict;
use warnings;
use v5.10;
use File::Slurp;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;

my $bullytime;
my $file = "../scrobbler.log";
for (@ARGV) {
    $bullytime = 0 if /bullshit-timestamps/;
    $file = $_ if -f $_;
}
-f $file or die "no such file: $file\n";

my @log = read_file($file);
my @set;
for (@log) {
    next if /^#/;
    my ($artist, $album, $song, $trackpos, $length, $rating, $ts) = split /\t/;
    if (defined $bullytime) {
        $ts = time - ((@log * 60 * 5) - ($bullytime++ * 60 * 5));
    }
    say "(".scalar(localtime($ts)).") $artist - $song";
    push @set, {
        artist => $artist,
        album => $album,
        track => $song,
        timestamp => $ts,
    };
    submat() if @set == 50
}
submat() if @set;
my $totally;
sub submat {
    my $res = lastfm(
        "track.scrobble",
        format => "xml",
        @set,
    );
    my $n = @set;
    unless ($res =~ /accepted="$n"/) {
        say "For fucks sake: $res";
        say "Consider --bullshit-timestamps" if $res =~ /Timestamp failed/;
        exit;
    }
    say "Submit a batch of $n";
    $totally += $n;
    @set = ();
}
say "Total: $totally";

