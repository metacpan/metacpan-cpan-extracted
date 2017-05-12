#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Runloop;

# Test create _mk_runloop
my $i = 0;

# Actions
my $engine = VS::RuleEngine::Engine->new();
$engine->add_rule(rule1 => "VS::RuleEngine::Rule::Perl", undef, sub { return KV_MATCH; });
$engine->add_rule(rule2 => "VS::RuleEngine::Rule::Perl", undef, sub { return KV_NO_MATCH; });

$engine->add_action(action1 => "VS::RuleEngine::Action::Perl", undef, sub { ok(++$i == 1); });
$engine->add_action(action2 => "VS::RuleEngine::Action::Perl", undef, sub { ok(++$i == 2); });
$engine->add_action(action3 => "VS::RuleEngine::Action::Perl", undef, sub { ok(0); });

$engine->add_rule_action(rule1 => "action1");
$engine->add_rule_action(rule1 => "action2");
$engine->add_rule_action(rule2 => "action3");

my $cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();

# Arguments
$engine = VS::RuleEngine::Engine->new();
$engine->add_rule(rule1 => "VS::RuleEngine::Rule::Perl", undef, sub { return KV_MATCH; });
$engine->add_action(action1 => "VS::RuleEngine::Action::Perl", undef, sub { 
    my ($self, $input, $global, $local) = @_[KV_SELF, KV_INPUT, KV_GLOBAL, KV_LOCAL];

    isa_ok($self, "VS::RuleEngine::Action::Perl");
    isa_ok($input, "VS::RuleEngine::InputHandler");
    isa_ok($global, "VS::RuleEngine::Data");
    isa_ok($local, "VS::RuleEngine::Data");
});
$engine->add_rule_action(rule1 => "action1");

$cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();
