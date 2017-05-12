use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

$ENV{ TEST_AUTHOR } =~ /WWW::Ohloh::API/ and eval q{
    use Test::Perl::Critic;
    goto RUN_TESTS;
};

plan skip_all => $@
       ? 'Test::Perl::Critic not installed; skipping perlcritic testing'
       :   q{set TEST_AUTHOR to 'WWW::Ohloh::API' in your environment }
         . q{to enable these tests};

RUN_TESTS: 

Test::Perl::Critic::all_critic_ok();
