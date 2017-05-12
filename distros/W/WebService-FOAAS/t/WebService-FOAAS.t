#!/usr/bin/perl
use 5.014000;
use strict;
use warnings;

use Test::RequiresInternet 'foaas.com' => 443;
use Test::More tests => 3;
BEGIN { use_ok('WebService::FOAAS') };

my $res;

$res = foaas_cool 'MGV';
is $res, 'Cool story, bro. - MGV', 'cool';

$res = foaas_dosomething 'Do', 'thing', 'MGV', {shoutcloud => 1};
is $res, 'DO THE FUCKING THING! - MGV', 'dosomething + shoutcloud';
