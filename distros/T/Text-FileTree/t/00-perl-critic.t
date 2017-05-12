#!/usr/bin/perl
use Test::Perl::Critic (-profile => ".perlcriticrc");
all_critic_ok(qw(lib));
