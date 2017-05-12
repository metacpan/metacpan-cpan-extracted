#! /usr/bin/perl
#---------------------------------------------------------------------
# perlcritic.t
#---------------------------------------------------------------------

use Test::More;

# ProhibitAccessOfPrivateData thinks hashrefs are objects
eval <<'';
use Test::Perl::Critic (qw(-verbose 10
                           -exclude) => ['ProhibitAccessOfPrivateData']);

plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

all_critic_ok();
