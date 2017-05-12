#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

use VS::RuleEngine::Engine;

use lib 't/lib';

use Test::VS::RuleEngine::Hook;

my $engine = VS::RuleEngine::Engine->new();

# Pre hook
throws_ok {
	$engine->add_hook(undef);
} qr/Name is undefined/;

throws_ok {
	$engine->add_hook("_Foo");
} qr/Name '_Foo' is invalid/;

throws_ok {
	$engine->add_hook(Foo => 0);
} qr/Hook '0' doesn't look like a valid class name/;

throws_ok {
	$engine->add_hook(Foo => "");
} qr/Hook '' doesn't look like a valid class name/;

throws_ok {
	$engine->add_hook(Foo => bless {}, "Foo");
} qr/Hook is an instance that does not conform to VS::RuleEngine::Hook/;

throws_ok {
	$engine->add_hook(Foo => "VS::RuleEngine::Input::NonExistent");
} qr{Can't locate VS/RuleEngine/Input/NonExistent.pm};

throws_ok {
	$engine->add_hook(Foo => "VS::RuleEngine::Rule");	
} qr/Hook 'VS::RuleEngine::Rule' does not conform to VS::RuleEngine::Hook/;

lives_ok {
	$engine->add_hook(Foo => "VS::RuleEngine::Hook");
};

throws_ok {
	$engine->add_hook(Foo => "VS::RuleEngine::Hook");    
} qr/Hook 'Foo' is already defined/;

lives_ok {
    $engine->add_hook(Bar => Test::VS::RuleEngine::Hook->new());
};

ok($engine->has_hook("Foo"));