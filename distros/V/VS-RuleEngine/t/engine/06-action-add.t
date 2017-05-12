#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use VS::RuleEngine::Engine;

use lib 't/lib';

use Test::VS::RuleEngine::Action;

my $engine = VS::RuleEngine::Engine->new();

# Action
throws_ok {
	$engine->add_action(undef);
} qr/Name is undefined/;

throws_ok {
	$engine->add_action(2342 => undef);
} qr/Name '2342' is invalid/;

throws_ok {
	$engine->add_action(Foo => undef);
} qr/Action is undefined/;

throws_ok {
	$engine->add_action(Foo => "");
} qr/Action '' doesn't look like a valid class name/;

throws_ok {
	$engine->add_action(Foo => 2554);
} qr/Action '2554' doesn't look like a valid class name/;

throws_ok {
	$engine->add_action(Foo => bless({}, "Bar"));
} qr/Action is an instance that does not conform to VS::RuleEngine::Action/;

throws_ok {
	$engine->add_action(Foo => 'VS::RuleEngine::Action::NonExistent');
} qr{Can't locate VS/RuleEngine/Action/NonExistent.pm};

throws_ok {
	$engine->add_action(Foo => "VS::RuleEngine::Rule");	
} qr/Action 'VS::RuleEngine::Rule' does not conform to VS::RuleEngine::Action/;

lives_ok {
	$engine->add_action(Foo => "VS::RuleEngine::Action");
};

throws_ok {
	$engine->add_action(Foo => "VS::RuleEngine::Action");    
} qr/Action 'Foo' is already defined/;

lives_ok {
	$engine->add_action(Bar => Test::VS::RuleEngine::Action->new());
};

# Getting
my $input = $engine->_get_action("Foo");
is($input->_pkg, "VS::RuleEngine::Action");

throws_ok {
	$engine->_get_action("Baz");
} qr/Can't find action 'Baz'/;

is_deeply([sort $engine->actions], [qw(Bar Foo)]);