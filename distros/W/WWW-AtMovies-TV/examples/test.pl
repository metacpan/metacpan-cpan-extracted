#!/usr/bin/env perl
#===============================================================================
#       AUTHOR:  Alec Chen , <alec@cpan.org>
#===============================================================================

use strict;
use warnings;
use WWW::AtMovies::TV;
use Data::TreeDumper;

my $tv = WWW::AtMovies::TV->new;
print DumpTree($tv->now);
my %now = $tv->now;

print DumpTree(\%now);
print DumpTree($tv->next);

my %next = $tv->next;
print DumpTree(\%next);
