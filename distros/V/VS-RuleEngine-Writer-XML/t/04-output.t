#!perl

use strict;
use warnings;

use Test::More tests => 1;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

my $engine = engine {
    output "output2" => instanceof "VS::RuleEngine::Output" => with_args {
        foo => 1,
        bar => 2,
    };

    output "output1" => instanceof "VS::RuleEngine::Output";
};

my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
is($xml, q{<?xml version="1.0"?>
<engine>
  <output name="output1" instanceOf="VS::RuleEngine::Output"/>
  <output name="output2" instanceOf="VS::RuleEngine::Output">
    <bar>2</bar>
    <foo>1</foo>
  </output>
</engine>
});

