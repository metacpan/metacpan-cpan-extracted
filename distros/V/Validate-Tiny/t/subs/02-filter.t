#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Validate::Tiny ':all';

is ref(filter('trim')), 'CODE';
is ref(filter(qw/trim strip/)), 'ARRAY';
{
    local $@;
    eval { filter('missing') };
    ok $@;
}

