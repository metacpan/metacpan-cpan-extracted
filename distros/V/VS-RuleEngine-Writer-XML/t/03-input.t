#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    input "input2" => instanceof "VS::RuleEngine::Input" => with_args {
        foo => 1,
        bar => 2,
    };

    input "input1" => instanceof "VS::RuleEngine::Input";
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <input name="input1" instanceOf="VS::RuleEngine::Input"/>
  <input name="input2" instanceOf="VS::RuleEngine::Input">
    <bar>2</bar>
    <foo>1</foo>
  </input>
</engine>
});

