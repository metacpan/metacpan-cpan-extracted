#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;
use VS::RuleEngine::Hook::Perl;

# Single hook
my $engine = VS::RuleEngine::Engine->new();

$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl" => sub {});
$engine->add_post_hook("hook1");

is_deeply($engine->_post_hooks, [qw(hook1)]);
# Multiple hooks

$engine = VS::RuleEngine::Engine->new();

$engine->add_hook(hook1 => "VS::RuleEngine::Hook::Perl" => sub {});
$engine->add_hook(hook2 => "VS::RuleEngine::Hook::Perl" => sub {});

$engine->add_post_hook("hook1");
$engine->add_post_hook("hook2");

is_deeply($engine->_post_hooks, [qw(hook1 hook2)]);
