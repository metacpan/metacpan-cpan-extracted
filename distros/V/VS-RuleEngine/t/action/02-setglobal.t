#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Declare;

BEGIN { use_ok("VS::RuleEngine::Action::SetGlobal"); }

my $engine = engine {
    rule "r1" => does {
        return KV_MATCH;
    };
    
    action "a1" => instanceof "VS::RuleEngine::Action::SetGlobal" => with_args {
       foo => 1,
       bar => 2,
    };
    
    run a1 => when "r1";
    
    posthook "h1" => does {
        my $global = $_[KV_GLOBAL];
        
        ok($global->exists("foo"));
        is($global->get("foo"), 1);
        
        ok($global->exists("bar"));
        is($global->get("bar"), 2);
        
        return KV_ABORT;
    };
};

$engine->run();
