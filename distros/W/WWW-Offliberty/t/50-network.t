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
cmp_ok @results, '>=', 1, 'vimeo, video_file => 1';

my $allresults = join ' ', @results;
like $allresults, qr/\.mp4/, 'some URL contains ".mp4"';
unlike $allresults, qr/offwarning/, 'no URL contains "offwarning"';
