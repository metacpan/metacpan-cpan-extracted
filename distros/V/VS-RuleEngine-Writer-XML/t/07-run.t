#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    action "action1" => instanceof "VS::RuleEngine::Action";
    action "action2" => instanceof "VS::RuleEngine::Action";
    
    rule "rule1" => instanceof "VS::RuleEngine::Rule";
    rule "rule2" => instanceof "VS::RuleEngine::Rule";
    rule "rule3" => instanceof "VS::RuleEngine::Rule";
    rule "rule4" => instanceof "VS::RuleEngine::Rule";
    
    run "action1" => when qw(rule1 rule2 rule4);
    run "action2" => when qw(rule3);
    
    run "action2" => when qw(rule4);
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <action name="action1" instanceOf="VS::RuleEngine::Action"/>
  <action name="action2" instanceOf="VS::RuleEngine::Action"/>
  <rule name="rule1" instanceOf="VS::RuleEngine::Rule"/>
  <rule name="rule2" instanceOf="VS::RuleEngine::Rule"/>
  <rule name="rule3" instanceOf="VS::RuleEngine::Rule"/>
  <rule name="rule4" instanceOf="VS::RuleEngine::Rule"/>
  <run action="action1">
    <rule>rule1</rule>
    <rule>rule2</rule>
    <rule>rule4</rule>
  </run>
  <run action="action2">
    <rule>rule3</rule>
    <rule>rule4</rule>
  </run>
</engine>
});

