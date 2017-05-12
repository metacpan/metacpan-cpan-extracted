#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    prehook "hook1" => instanceof "VS::RuleEngine::Hook";
    posthook "hook2" => instanceof "VS::RuleEngine::Hook";

    prehook "hook3" => instanceof "VS::RuleEngine::Hook";
    posthook "hook4" => instanceof "VS::RuleEngine::Hook";
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <prehook name="hook1" instanceOf="VS::RuleEngine::Hook"/>
  <prehook name="hook3" instanceOf="VS::RuleEngine::Hook"/>
  <posthook name="hook2" instanceOf="VS::RuleEngine::Hook"/>
  <posthook name="hook4" instanceOf="VS::RuleEngine::Hook"/>
</engine>
});

