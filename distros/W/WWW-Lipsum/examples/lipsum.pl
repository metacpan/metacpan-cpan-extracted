#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{../lib lib};
use WWW::Lipsum;

my $lipsum = WWW::Lipsum->new(
    html => 0, amount => 5, what => 'paras', start => 0
);

print "$lipsum\n";
