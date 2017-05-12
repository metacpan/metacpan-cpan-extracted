#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use VS::RuleEngine::Engine;
use VS::RuleEngine::Rule::Perl;
use VS::RuleEngine::Action::Perl;

my $engine = VS::RuleEngine::Engine->new();

$engine->add_rule("rule1" => "VS::RuleEngine::Rule::Perl" => sub {});
is_deeply($engine->_get_rule_actions("rule1"), []);

$engine->add_action("action1" => "VS::RuleEngine::Action::Perl" => sub {});

$engine->add_rule_action("rule1" => "action1");
is_deeply($engine->_get_rule_actions("rule1"), [qw(action1)]);

throws_ok {
    $engine->add_rule_action("rule2" => "action2");
} qr/Rule 'rule2' does not exist/;