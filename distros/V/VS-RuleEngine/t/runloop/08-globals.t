#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Data;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Runloop;

my $engine = VS::RuleEngine::Engine->new();
$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { 
    my $global = $_[KV_GLOBAL];
    isa_ok($global, "VS::RuleEngine::Data");
    is_deeply([$global->keys], []);
    
    return KV_ABORT;
});

$engine->add_pre_hook("hook1");

my $runloop = VS::RuleEngine::Runloop->new();
$runloop->add_engine($engine);
$runloop->run();

# Using a global data
my $data = VS::RuleEngine::Data->new();
$data->set(test => 1);

$engine = VS::RuleEngine::Engine->new();
$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { 
    my $global = $_[KV_GLOBAL];
    isa_ok($global, "VS::RuleEngine::Data");
    ok($global->exists("test"));
    is($global->get("test"), 1);
    return KV_ABORT;
});

$engine->add_pre_hook("hook1");

$runloop = VS::RuleEngine::Runloop->new();
$runloop->add_engine($engine, $data);
$runloop->run();
