#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Runloop;

# Test create _mk_runloop
my $i = 0;

# Rules
my $engine = VS::RuleEngine::Engine->new();
$engine->add_rule(rule1 => "VS::RuleEngine::Rule::Perl", undef, sub { ok(++$i == 1); return KV_NO_MATCH; });
$engine->add_rule(rule2 => "VS::RuleEngine::Rule::Perl", undef, sub { ok(++$i == 2); return KV_MATCH; });

# This should never be ran and if it does it'll produce an error
$engine->add_rule(rule3 => "VS::RuleEngine::Rule::Perl", undef, sub { ok(0); return KV_MATCH; }); 

my $cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();

# Arguments
$engine = VS::RuleEngine::Engine->new();
$engine->add_rule(hook1 => "VS::RuleEngine::Rule::Perl", undef, sub {
    my ($self, $input, $global, $local) = @_[KV_SELF, KV_INPUT, KV_GLOBAL, KV_LOCAL];

    isa_ok($self, "VS::RuleEngine::Rule::Perl");
    isa_ok($input, "VS::RuleEngine::InputHandler");
    isa_ok($global, "VS::RuleEngine::Data");
    isa_ok($local, "VS::RuleEngine::Data");
});

$cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();