#!perl

use strict;
use warnings;

use File::Spec ();
use Test::More;

unless ( $ENV{TEST_AUTHOR} ) {
    plan skip_all =>
      'Set $ENV{TEST_AUTHOR} to a true value to run critic tests.';
}

eval { require Test::Perl::Critic };
if ($@) {
    plan skip_all => 'Test::Perl::Critic required to criticise code.';
}

my $rcfile = File::Spec->catfile( 't', '_perlcriticrc.txt' );

Test::Perl::Critic->import( -profile => $rcfile );

all_critic_ok();
