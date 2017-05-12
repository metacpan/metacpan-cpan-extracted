#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use POSIX qw(tmpnam);
use Test::More tests => 4;

require_ok('Text::Playlist::M3U');

my $pls = new_ok('Text::Playlist::M3U' => []);

my $text = <<M3U;
#EXTM3U aspect-ratio=4:3
#EXTINF:-1,First channel
http://127.0.0.1:1027/udp/224.3.22.7:1234
#EXTINF:-1 cn-id=34727751, Second channel +8
http://127.0.0.1:1027/udp/224.3.23.9:1234
M3U

my $path = tmpnam();
open my $FH, ">", $path;
print $FH $text;
close $FH;

my $out = [{
  attrs    => {},
  file     => 'http://127.0.0.1:1027/udp/224.3.22.7:1234',
  title    => 'First channel',
  duration => '-1',
}, {
  attrs    => { 'cn-id' => '34727751' },
  file     => 'http://127.0.0.1:1027/udp/224.3.23.9:1234',
  title    => 'Second channel +8',
  duration => '-1',
}];

my @items = $pls->load($path);
is_deeply(\@items, $out, "Loading test playlist");
unlink $path;

$text =~ s/,\s+Second/,Second/o;
is($text, $pls->dump(@items));

exit 0;
