#!perl

use strict;
use warnings;

# +1 for Test::NoWarnings
use Test::More tests => 2 + 1;
use Test::NoWarnings;

use_ok 'WebService::Flattr';
my $flattr = WebService::Flattr->new();
isa_ok $flattr, 'WebService::Flattr';
