#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    defaults "defaults1" => {
        foo => 1,
    };
    
    defaults "defaults2" => {
        bar => 2,
        baz => 3,
    };
    
    action "action1" => instanceof "VS::RuleEngine::Action" => with_defaults "defaults1";
    action "action2" => instanceof "VS::RuleEngine::Action" => with_defaults [qw(defaults1 defaults2)];
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <defaults name="defaults1">
    <foo>1</foo>
  </defaults>
  <defaults name="defaults2">
    <bar>2</bar>
    <baz>3</baz>
  </defaults>
  <action name="action1" instanceOf="VS::RuleEngine::Action" defaults="defaults1"/>
  <action name="action2" instanceOf="VS::RuleEngine::Action" defaults="defaults1, defaults2"/>
</engine>
});

