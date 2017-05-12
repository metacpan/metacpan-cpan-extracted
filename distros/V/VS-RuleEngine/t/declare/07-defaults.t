#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use VS::RuleEngine::Declare;

use lib 't/lib';

my $engine = engine {
    defaults "d1" => {
        foo => 1,
    };
    
    defaults "d2" => {
        bar => 2,
    };
    
    action "a1" => instanceof "Test::VS::RuleEngine::Action" => with_defaults "d1";
    action "a2" => instanceof "Test::VS::RuleEngine::Action" => with_defaults [qw(d1 d2)];
};

ok($engine->has_defaults("d1"));
my $defaults = $engine->get_defaults("d1");
ok(defined $defaults);
is_deeply($defaults, { foo => 1 });

ok($engine->has_defaults("d2"));
$defaults = $engine->get_defaults("d2");
ok(defined $defaults);
is_deeply($defaults, { bar => 2 });

ok($engine->has_action("a1"));
my $action = $engine->_get_action("a1")->instantiate($engine);
is_deeply($action, { foo => 1 });

ok($engine->has_action("a2"));
$action = $engine->_get_action("a2")->instantiate($engine);
is_deeply($action, { foo => 1, bar => 2 });

