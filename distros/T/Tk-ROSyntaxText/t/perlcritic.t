#!perl -T

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

BEGIN {
    if (! $ENV{CPAN_TEST_AUTHOR}) {
        plan skip_all
            => q[Author test.]
             . q[ To run: set $ENV{CPAN_TEST_AUTHOR} to a TRUE value.];
    }
}

# Perl::Critic Exclusions
#   ProhibitAccessOfPrivateData
#       Can't distinguish $hash_ref->{$key} from $blessed_object->{$inst_var}
eval {
    use Test::Perl::Critic 1.02 (
        -exclude => [q{ProhibitAccessOfPrivateData}]
    );
};

if ($EVAL_ERROR) {
    plan skip_all
        => q{Test::Perl::Critic 1.02 required for testing PBP compliance};
}

Test::Perl::Critic::all_critic_ok();
