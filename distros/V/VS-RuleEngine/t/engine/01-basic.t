#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN { use_ok("VS::RuleEngine::Engine"); }

my $engine = VS::RuleEngine::Engine->new();
isa_ok($engine, "VS::RuleEngine::Engine");
