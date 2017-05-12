#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    action "action2" => instanceof "VS::RuleEngine::Action" => with_args {
        foo => 1,
        bar => 2,
    };

    action "action1" => instanceof "VS::RuleEngine::Action";
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <action name="action1" instanceOf="VS::RuleEngine::Action"/>
  <action name="action2" instanceOf="VS::RuleEngine::Action">
    <bar>2</bar>
    <foo>1</foo>
  </action>
</engine>
});

