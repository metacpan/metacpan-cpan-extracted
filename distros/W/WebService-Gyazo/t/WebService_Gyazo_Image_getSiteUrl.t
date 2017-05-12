#!/usr/bin/env perl

use Data::Dumper;
use Test::More tests => 3;

use lib 'lib/';

use_ok('WebService::Gyazo::Image');

my $image = WebService::Gyazo::Image->new(id => '10222');
can_ok($image, 'getSiteUrl');

is($image->getSiteUrl(), 'http://gyazo.com/10222', 'WebService::Gyazo::Image->useOk(\'getSiteUrl\')');