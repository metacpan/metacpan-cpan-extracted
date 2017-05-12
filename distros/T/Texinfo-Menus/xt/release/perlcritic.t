#!perl
#---------------------------------------------------------------------
# perlcritic.t
#---------------------------------------------------------------------

use Test::More;

eval "use Test::Perl::Critic qw(-verbose 10)";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

all_critic_ok();
