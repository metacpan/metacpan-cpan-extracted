#!perl

use Test::More;
eval "use Test::Perl::Critic";

if ($@) {
    Test::More::plan( skip_all =>
            "Test::Perl::Critic required for testing PBP compliance" );
}
else {
    Test::Perl::Critic->import(
        -verbose  => 8,
        -severity => 5,
        -exclude => [
            'ProhibitAccessOfPrivateData',    # false positives
        ]
    );
}

Test::Perl::Critic::all_critic_ok();
