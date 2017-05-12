#!/usr/bin/env perl
#===============================================================================
#       AUTHOR:  Alec Chen , <alec@cpan.org>
#===============================================================================

use strict;
use warnings;
use WWW::NioTV;
use Data::TreeDumper;
use Time::HiRes qw(time);

my $start = time;
my $tv = WWW::NioTV->new;
printf "time = %f\n", time - $start;

my %now = $tv->now;
print DumpTree(\%now);
printf "time = %f\n", time - $start;

my %next = $tv->next;
print DumpTree(\%next);
printf "time = %f\n", time - $start;
