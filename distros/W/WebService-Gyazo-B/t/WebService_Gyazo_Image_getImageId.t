#!/usr/bin/env perl

use Data::Dumper;
use Test::More tests => 3;

use lib 'lib/';

use_ok('WebService::Gyazo::B::Image');

my $image = WebService::Gyazo::B::Image->new(id => '10222');
can_ok($image, 'getImageId');

is($image->getImageId(), '10222', 'WebService::Gyazo::B::Image->useOk(\'getImageId\')');
