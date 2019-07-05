package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Test::Pod::LinkCheck::Lite'
    or BAIL_OUT $@;

my $ms = eval { Test::Pod::LinkCheck::Lite->new() };
isa_ok $ms, 'Test::Pod::LinkCheck::Lite'
    or BAIL_OUT $@;

done_testing;

1;
