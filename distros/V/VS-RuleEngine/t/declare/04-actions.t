#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use VS::RuleEngine::Declare;

use lib 't/lib';

use Test::VS::RuleEngine::Action;

my $action_obj = Test::VS::RuleEngine::Action->new();

my $engine = engine {
    action "action1" => instanceof "Test::VS::RuleEngine::Action";
    action "action2" => instanceof "Test::VS::RuleEngine::Action" => with_args {
        start => 10
    };
    
    action "action3" => does {
        1;
    };
    
    action "action4" => $action_obj;
};

ok($engine->has_action("action1"));
my $action = $engine->_get_action("action1");
ok(defined $action);
is($action->_pkg, "Test::VS::RuleEngine::Action");
is_deeply($action->_args, []);

ok($engine->has_action("action2"));
$action = $engine->_get_action("action2");
ok(defined $action);
is($action->_pkg, "Test::VS::RuleEngine::Action");
is_deeply($action->_args, [start => 10]);

ok($engine->has_action("action3"));
$action = $engine->_get_action("action3");
ok(defined $action);
is($action->_pkg, "VS::RuleEngine::Action::Perl");
is($action->_args->[0]->(), 1);

ok($engine->has_action("action4"));
$action = $engine->_get_action("action4");
ok(defined $action);
ok($action->_pkg == $action_obj);