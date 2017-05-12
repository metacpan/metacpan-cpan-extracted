#!/usr/bin/env perl

use Data::Dumper;
use Test::More tests => 3;

use lib 'lib/';

use_ok('WebService::Gyazo::B::Image');

my $image = WebService::Gyazo::B::Image->new(id => '10222');
can_ok($image, 'getImageUrl');

is($image->getImageUrl(), 'http://gyazo.com/10222.png', 'WebService::Gyazo::B::Image->useOk(\'getImageUrl\')');
