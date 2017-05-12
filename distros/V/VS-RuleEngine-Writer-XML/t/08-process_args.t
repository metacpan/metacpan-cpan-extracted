#!perl

package Test::VS::RuleEngine::Input;

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Writer::XML;

use base qw(VS::RuleEngine::Input);

sub process_xml_writer_args {
    my ($self, $doc, $parent, %args) = @_;
    
    is($self, "Test::VS::RuleEngine::Input");
    isa_ok($doc, "XML::LibXML::Document");
    isa_ok($parent, "XML::LibXML::Element");
    is_deeply(\%args, { foo => 1, bar => 2 });
    
    $parent->appendText("foo");
}

my $engine = engine {
    input "input1" => instanceof "Test::VS::RuleEngine::Input" => with_args {
        foo => 1,
        bar => 2,
    };
};

my $as_xml = VS::RuleEngine::Writer::XML->as_xml($engine);

is($as_xml, q{<?xml version="1.0"?>
<engine>
  <input name="input1" instanceOf="Test::VS::RuleEngine::Input">foo</input>
</engine>
});