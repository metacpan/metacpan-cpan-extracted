#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Declare;

BEGIN { use_ok("VS::RuleEngine::Action::SetLocal"); }

my $engine = engine {
    rule "r1" => does {
        return KV_MATCH;
    };
    
    action "a1" => instanceof "VS::RuleEngine::Action::SetLocal" => with_args {
       foo => 1,
       bar => 2,
    };
    
    run a1 => when "r1";
    
    posthook "h1" => does {
        my $local = $_[KV_LOCAL];
        
        ok($local->exists("foo"));
        is($local->get("foo"), 1);
        
        ok($local->exists("bar"));
        is($local->get("bar"), 2);
        
        return KV_ABORT;
    };
};

$engine->run();
