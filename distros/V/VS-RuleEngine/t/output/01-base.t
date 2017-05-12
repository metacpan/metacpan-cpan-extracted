#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::AbstractMethod;

BEGIN { use_ok("VS::RuleEngine::Output"); }

for my $method (qw(pre_process process post_process)) {
	call_abstract_method_ok("VS::RuleEngine::Output", $method);
	call_abstract_class_method_ok("VS::RuleEngine::Output", $method);
	call_abstract_function_ok("VS::RuleEngine::Output", $method);
}