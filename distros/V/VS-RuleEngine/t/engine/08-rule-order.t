#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use VS::RuleEngine::Engine;

my $engine = VS::RuleEngine::Engine->new();

$engine->add_rule(Foo => "Test::VS::RuleEngine::Rule");
$engine->add_rule(baz => "Test::VS::RuleEngine::Rule");
$engine->add_rule(bar => "Test::VS::RuleEngine::Rule");

is_deeply([$engine->rule_order], [qw(Foo baz bar)]);

$engine->set_rule_order(qw(Foo bar baz));

is_deeply([$engine->rule_order], [qw(Foo bar baz)]);