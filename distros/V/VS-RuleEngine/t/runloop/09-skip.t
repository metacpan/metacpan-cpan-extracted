#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Constants;

my $evaluate = 0;
my $skip_test = 0;
my $skip_test_a = 1;
my $dont_evaluate = 1;
my $output = 1;

my $engine = engine {
    rule evaluate => does {
        $evaluate = 1;
        return KV_NO_MATCH;
    };
    
    rule skip_test => does {
        $skip_test = 1;
        return KV_SKIP;
    };
    
    rule dont_evaluate => does {
        $dont_evaluate = 0;
        return KV_MATCH;
    };
    
    action skip_test_a => does {
        $skip_test_a = 0;
    };
    
    run skip_test_a => when qw(skip_test);
    
    posthook quit => does {
        return KV_ABORT;
    };
    
    output foo => does {
        $output = 0;
    }
};

$engine->run();

is($evaluate, 1, "Ran evalate rule");
is($skip_test, 1, "Ran skip_test rule");
is($dont_evaluate, 1, "Didn't run dont_evaluate rule");
is($skip_test_a, 1, "Didn't run skip_test_a rule");
is($output, 1, "Didn't run foo output");

