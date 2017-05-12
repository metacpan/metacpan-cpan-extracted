#!perl

use Test::More;
eval q{ use Test::Perl::Critic (-format => " => [%p] %m at line %l, column %c. %e."); };
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
