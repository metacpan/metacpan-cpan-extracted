#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use WWW::HTMLTagAttributeCounter;

my $c = WWW::HTMLTagAttributeCounter->new;

my $r = $c->count( 'zoffix.com', [ qw/a span div/ ], )
    or die "Error: " . $c->error . "\n";

print "I counted $c tags on zoffix.com\n";