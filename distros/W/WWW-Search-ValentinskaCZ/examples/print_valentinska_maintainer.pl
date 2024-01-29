#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Search;

# Object.
my $obj = WWW::Search->new('ValentinskaCZ');

print $obj->maintainer."\n";

# Output:
# Michal Josef Spacek <skim@cpan.org>