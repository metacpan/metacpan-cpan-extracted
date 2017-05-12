#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;

eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

#my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
#Test::Perl::Critic->import( -profile => $rcfile );
Test::Perl::Critic::all_critic_ok('lib');

