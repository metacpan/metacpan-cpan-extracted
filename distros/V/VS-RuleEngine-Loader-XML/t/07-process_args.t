#!perl

package Test::VS::RuleEngine::Input2;

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Loader::XML;

use base qw(VS::RuleEngine::Input);

sub process_xml_loader_args {
    my ($self, $element) = @_;
    
    is($self, "Test::VS::RuleEngine::Input2");
    isa_ok($element, "XML::LibXML::Element");
    my $text = $element->textContent();
    return ($text);
}

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <input name="input1" instanceOf="Test::VS::RuleEngine::Input2">IZ DIS VALID ARGUMENT?</input>
    </engine>
});

ok($engine->has_input("input1"));
my $input = $engine->_get_input("input1");
ok(defined $input);
is_deeply($input->_args, ['IZ DIS VALID ARGUMENT?']);


