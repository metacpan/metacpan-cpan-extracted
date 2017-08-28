#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet 'offliberty.com' => 80;
use Test::More tests => 4;
use WWW::Offliberty qw/off/;

my @results;
@results = off 'https://vimeo.com/45196609';
cmp_ok @results, '>=', 1, 'vimeo';

@results = off 'https://vimeo.com/45196609', video_file => 1;
is @results, 2, 'vimeo, video_file => 1';

like $results[1], qr/\.mp4/, 'video URL contains ".mp4"';
unlike $results[0], qr/offwarning/, 'audio URL doesn\'t contain "offwarning"';
