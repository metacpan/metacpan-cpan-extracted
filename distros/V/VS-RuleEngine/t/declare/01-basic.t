#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use VS::RuleEngine::Engine;

BEGIN { use_ok("VS::RuleEngine::Declare"); }

my $engine = engine {};
isa_ok($engine, "VS::RuleEngine::Engine");
