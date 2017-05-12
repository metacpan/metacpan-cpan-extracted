#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More qw( no_plan );

use lib 'lib/';

use_ok('WebService::Gyazo::B');

my $ua = WebService::Gyazo::B->new();
can_ok($ua, 'uploadFile');

my $image = $ua->uploadFile('t/img.jpg');

if ($image eq 0)
{
    ok(0, "uploadFile() Returned 0 ; error=[" . $ua->error() . "]");
    exit(-1);
}

isa_ok($image, 'WebService::Gyazo::B::Image');

like($image->getImageId, qr/^\w+$/, '$image->getImageId == \w+ ['.$image->getImageId.']');
like($image->getImageUrl, qr#^http://gyazo\.com/\w+\.png$#, '$image->getImageUrl == \w+ ['.$image->getImageUrl.']');
like($image->getSiteUrl, qr#^http://gyazo\.com/\w+$#, '$image->getSiteUrl == \w+ ['.$image->getSiteUrl.']');
