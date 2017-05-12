#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Runloop;
use VS::RuleEngine::Engine;

my $i = 0;

my $engine1 = VS::RuleEngine::Engine->new();
$engine1->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 1); return KV_ABORT; });
$engine1->add_pre_hook("hook1");

my $engine2 = VS::RuleEngine::Engine->new();
$engine2->add_hook(hook1 => "VS::RuleEngine::Hook::Perl", undef, sub { ok(++$i == 2); return KV_ABORT; });
$engine2->add_pre_hook("hook1");

my $runloop = VS::RuleEngine::Runloop->new();
$runloop->add_engine($engine1);
$runloop->add_engine($engine2);

$runloop->run();
