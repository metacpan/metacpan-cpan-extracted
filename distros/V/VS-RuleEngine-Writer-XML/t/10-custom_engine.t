#!perl

package Test::VS::RuleEngine::Engine;

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Writer::XML;

use base qw(VS::RuleEngine::Engine);

my $engine = Test::VS::RuleEngine::Engine->new();

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine instanceOf="Test::VS::RuleEngine::Engine"/>
});

