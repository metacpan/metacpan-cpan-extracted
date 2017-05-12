#!perl

use Test::More;

plan skip_all => 'set DEVELOPER_TESTS to enable this test (developer only!)'
  unless $ENV{DEVELOPER_TESTS};


if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
