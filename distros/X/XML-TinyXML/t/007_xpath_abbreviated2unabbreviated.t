
use strict;
use Test::More tests => 9;
use XML::TinyXML;
use XML::TinyXML::Selector;
use Data::Dumper;

my $txml = XML::TinyXML->new();
$txml->loadFile("./t/t.xml");
my $selector = XML::TinyXML::Selector->new($txml, "XPath");

is ($selector->_expand_abbreviated('div/para'), 'child::div/child::para');
is ($selector->_expand_abbreviated('para[@type="warning"]'), 'child::para[attribute::type="warning"]');
is ($selector->_expand_abbreviated('//'), '/descendant-or-self::node()');
is ($selector->_expand_abbreviated('//para'), '/descendant-or-self::node()/child::para');
is ($selector->_expand_abbreviated('div//para'), 'child::div/descendant-or-self::node()/child::para');
is ($selector->_expand_abbreviated('.'), 'self::node()');
is ($selector->_expand_abbreviated('.//para'), 'self::node()/descendant-or-self::node()/child::para');
is ($selector->_expand_abbreviated('..'), 'parent::node()');
is ($selector->_expand_abbreviated('../title'), 'parent::node()/child::title');
