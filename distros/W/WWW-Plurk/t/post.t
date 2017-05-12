use strict;
use warnings;
use Test::More tests => 1;

# TODO: Need to figure out how to test a post without actually
# posting...

package Fake::Plurk;
use strict;
use warnings;
use base qw( WWW::Plurk );

package main;

ok 1, 'is OK';
