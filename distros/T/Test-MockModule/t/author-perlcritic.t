#!perl
use strict;
use warnings;
use Test::More;

# Author/develop test: runs Perl::Critic against lib/ and t/ at the
# project's --gentle severity. Gated behind AUTHOR_TESTING so installers
# and CPAN testers (who may carry their own perlcritic policies) never
# run it -- only the author and CI (AUTHOR_TESTING=1) do. The install
# guard below is a second layer for the author-only dep.
plan skip_all => 'Author test; set AUTHOR_TESTING=1 to run'
    unless $ENV{AUTHOR_TESTING};

eval { require Test::Perl::Critic };
plan skip_all => 'Test::Perl::Critic not installed (author dep)' if $@;

Test::Perl::Critic->import(-severity => 'gentle');
all_critic_ok('lib', 't');
