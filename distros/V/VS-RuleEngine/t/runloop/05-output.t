#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Runloop;

# Test create _mk_runloop
my $i = 0;

# Actions
my $engine = VS::RuleEngine::Engine->new();
$engine->add_output(output1 => "VS::RuleEngine::Output::Perl", undef, sub { ok(++$i == 1); });

my $cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();

# Arguments
$engine = VS::RuleEngine::Engine->new();
$engine->add_output(output1 => "VS::RuleEngine::Output::Perl", undef, sub { 
    my ($self, $input, $global, $local) = @_[KV_SELF, KV_INPUT, KV_GLOBAL, KV_LOCAL];

    isa_ok($self, "VS::RuleEngine::Output::Perl");
    isa_ok($input, "VS::RuleEngine::InputHandler");
    isa_ok($global, "VS::RuleEngine::Data");
    isa_ok($local, "VS::RuleEngine::Data");
});

$cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();
