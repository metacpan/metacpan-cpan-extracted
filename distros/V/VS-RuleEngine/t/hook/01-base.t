#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::AbstractMethod;

BEGIN { use_ok("VS::RuleEngine::Hook") }

for my $method (qw(invoke)) {
	call_abstract_method_ok("VS::RuleEngine::Hook", $method);
	call_abstract_class_method_ok("VS::RuleEngine::Hook", $method);
	call_abstract_function_ok("VS::RuleEngine::Hook", $method);
}

