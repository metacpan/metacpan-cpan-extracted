#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 32;

use VS::RuleEngine::Declare;

use lib 't/lib';

use Test::VS::RuleEngine::Hook;

my $hook_obj1 = Test::VS::RuleEngine::Hook->new();
my $hook_obj2 = Test::VS::RuleEngine::Hook->new();

my $engine = engine {
    prehook "hook1" => instanceof "Test::VS::RuleEngine::Hook";
    prehook "hook2" => instanceof "Test::VS::RuleEngine::Hook" => with_args {
        start => 10
    };
    
    prehook "hook3" => does {
        1;
    };

    prehook "hook4" => $hook_obj1;
    
    posthook "hook5" => instanceof "Test::VS::RuleEngine::Hook";
    posthook "hook6" => instanceof "Test::VS::RuleEngine::Hook" => with_args {
        start => 10
    };
    
    posthook "hook7" => does {
        1;
    };

    posthook "hook8" => $hook_obj2;
};

ok($engine->has_hook("hook1"));

my $hook = $engine->_get_hook("hook1");
ok(defined $hook);
is($hook->_pkg, "Test::VS::RuleEngine::Hook");
is_deeply($hook->_args, []);

ok($engine->has_hook("hook2"));
$hook = $engine->_get_hook("hook2");
ok(defined $hook);
is($hook->_pkg, "Test::VS::RuleEngine::Hook");
is_deeply($hook->_args, [start => 10]);

ok($engine->has_hook("hook3"));
$hook = $engine->_get_hook("hook3");
ok(defined $hook);
is($hook->_pkg, "VS::RuleEngine::Hook::Perl");
is($hook->_args->[0]->(), 1);

ok($engine->has_hook("hook4"));
$hook = $engine->_get_hook("hook4");
ok(defined $hook);
ok($hook->_pkg == $hook_obj1);

is_deeply($engine->_pre_hooks, [qw(hook1 hook2 hook3 hook4)]);

ok($engine->has_hook("hook5"));
$hook = $engine->_get_hook("hook5");
ok(defined $hook);
is($hook->_pkg, "Test::VS::RuleEngine::Hook");
is_deeply($hook->_args, []);

ok($engine->has_hook("hook6"));
$hook = $engine->_get_hook("hook6");
ok(defined $hook);
is($hook->_pkg, "Test::VS::RuleEngine::Hook");
is_deeply($hook->_args, [start => 10]);

ok($engine->has_hook("hook7"));
$hook = $engine->_get_hook("hook7");
ok(defined $hook);
is($hook->_pkg, "VS::RuleEngine::Hook::Perl");
is($hook->_args->[0]->(), 1);

ok($engine->has_hook("hook8"));
$hook = $engine->_get_hook("hook8");
ok(defined $hook);
ok($hook->_pkg == $hook_obj2);

is_deeply($engine->_post_hooks, [qw(hook5 hook6 hook7 hook8)]);

