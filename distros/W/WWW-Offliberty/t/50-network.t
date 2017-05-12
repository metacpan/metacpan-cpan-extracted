#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet 'offliberty.com' => 80;
use Test::More tests => 4;
use WWW::Offliberty qw/off/;

my @results;
@results = off "https://youtube.com/watch?v=pJyQpAiMXkg";
cmp_ok @results, '>=', 1, 'youtube';

@results = off "https://youtube.com/watch?v=pJyQpAiMXkg", video_file => 1;
is @results, 2, 'youtube, video_file => 1';

like $results[1], qr/\.mp4/, 'video URL contains ".mp4"';
unlike $results[0], qr/offwarning/, 'audio URL doesn\'t contain "offwarning"';
