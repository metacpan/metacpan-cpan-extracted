#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'WWW::SchneierFacts';

my $s = WWW::SchneierFacts->new;

isa_ok( $s, "WWW::SchneierFacts" );

can_ok( $s, "fact", "top_facts", "random_fact" );
