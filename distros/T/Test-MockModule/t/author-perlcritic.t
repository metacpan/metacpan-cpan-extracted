#!perl
use strict;
use warnings;
use Test::More;

# Author/develop test: runs Perl::Critic against lib/ and t/ at the
# project's --gentle severity. Skipped on machines without
# Test::Perl::Critic so random CPAN testers do not fail because of an
# author-only dep.
eval { require Test::Perl::Critic };
plan skip_all => 'Test::Perl::Critic not installed (author dep)' if $@;

Test::Perl::Critic->import(-severity => 'gentle');
all_critic_ok('lib', 't');
