#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Runloop;

my $i = 0;
my $engine = VS::RuleEngine::Engine->new();
$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 1) });
$engine->add_pre_hook("hook1");
$engine->add_hook(hook2 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 2) });
$engine->add_pre_hook("hook2");
my $cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();

$engine = VS::RuleEngine::Engine->new();
$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 3) });
$engine->add_post_hook("hook1");
$engine->add_hook(hook2 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 4) });
$engine->add_post_hook("hook2");
$cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();

# Arguments
$engine = VS::RuleEngine::Engine->new();
$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub {
    my ($self, $input, $global, $local) = @_[KV_SELF, KV_INPUT, KV_GLOBAL, KV_LOCAL];

    isa_ok($self, "VS::RuleEngine::Hook::Perl");
    isa_ok($input, "VS::RuleEngine::InputHandler");
    isa_ok($global, "VS::RuleEngine::Data");
    isa_ok($local, "VS::RuleEngine::Data");
});

$engine->add_pre_hook("hook1");
$engine->add_post_hook("hook1");

$cb = VS::RuleEngine::Runloop::_mk_runloop($engine);
$cb->();