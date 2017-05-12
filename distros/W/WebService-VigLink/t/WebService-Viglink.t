#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('WebService::VigLink');
    can_ok('WebService::VigLink', qw( new make_url ));
};

eval { WebService::VigLink->new };
ok($@, 'exception thrown');


