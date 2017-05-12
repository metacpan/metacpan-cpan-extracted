#!perl 
use warnings;
use strict;

use Test::More;

{
    ## no critic

    eval " 
        use Test::Perl::Critic (-exclude => [
#                            'ProhibitNoStrict',
#                            'RequireBarewordIncludes',
#                            'ProhibitNestedSubs',
                        ]);
    ";
};

if ($@ or ! $ENV{RELEASE_TESTING}){
    plan skip_all => "Test::Perl::Critic not installed or not RELEASE_TESTING";
}

all_critic_ok('.');

