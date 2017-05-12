#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::AbstractMethod;

BEGIN { use_ok("VS::RuleEngine::Input"); }

for my $method (qw(value)) {
	call_abstract_method_ok("VS::RuleEngine::Input", $method);
	call_abstract_class_method_ok("VS::RuleEngine::Input", $method);
	call_abstract_function_ok("VS::RuleEngine::Input", $method);
}