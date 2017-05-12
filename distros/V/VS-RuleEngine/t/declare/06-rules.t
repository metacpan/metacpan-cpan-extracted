#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

use VS::RuleEngine::Declare;

use lib 't/lib';

use Test::VS::RuleEngine::Rule;

my $rule_obj = Test::VS::RuleEngine::Rule->new();

my $engine = engine {
    rule "rule1" => instanceof "Test::VS::RuleEngine::Rule";
    rule "rule2" => instanceof "Test::VS::RuleEngine::Rule" => with_args {
        start => 10,
    };
    
    rule "rule3" => does {
        1;
    };
    
    rule "rule4" => $rule_obj;
    
    action "action1" => does {};
    action "action2" => does {};
    action "action3" => does {};
    
    run "action1" => when qw(rule1 rule2);
    run "action2" => when "rule2";
    run "action3" => when qw(rule3);
};

ok($engine->has_rule("rule1"));
my $rule = $engine->_get_rule("rule1");
ok(defined $rule);
is($rule->_pkg, "Test::VS::RuleEngine::Rule");
is_deeply($rule->_args, []);

ok($engine->has_rule("rule2"));
$rule = $engine->_get_rule("rule2");
ok(defined $rule);
is($rule->_pkg, "Test::VS::RuleEngine::Rule");
is_deeply($rule->_args, [start => 10]);

ok($engine->has_rule("rule3"));
$rule = $engine->_get_rule("rule3");
ok(defined $rule);
is($rule->_pkg, "VS::RuleEngine::Rule::Perl");
is($rule->_args->[0]->(), 1);

ok($engine->has_rule("rule4"));
$rule = $engine->_get_rule("rule4");
ok(defined $rule);
ok($rule->_pkg == $rule_obj);

ok($engine->has_action("action1"));
ok($engine->has_action("action2"));
ok($engine->has_action("action3"));

is_deeply($engine->_rule_actions->get("rule1"), ['action1']);
is_deeply($engine->_rule_actions->get("rule2"), ['action1', 'action2']);
is_deeply($engine->_rule_actions->get("rule3"), ['action3']);