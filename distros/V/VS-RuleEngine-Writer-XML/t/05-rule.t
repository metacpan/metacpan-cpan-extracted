#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    rule "rule1" => instanceof "VS::RuleEngine::Rule";
    rule "rule3" => instanceof "VS::RuleEngine::Rule";
    rule "rule2" => instanceof "VS::RuleEngine::Rule" => with_args {
        foo => 1,
        bar => 2,
    };
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <rule name="rule1" instanceOf="VS::RuleEngine::Rule"/>
  <rule name="rule3" instanceOf="VS::RuleEngine::Rule"/>
  <rule name="rule2" instanceOf="VS::RuleEngine::Rule">
    <bar>2</bar>
    <foo>1</foo>
  </rule>
</engine>
});

