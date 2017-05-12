# vim: filetype=perl
use strict;

use Test::More;
use XML::LibXML;
use XML::SAX::IncrementalBuilder::LibXML;


plan 'no_plan';
#plan tests => @doc + 4;

use_ok("XML::Generator::XMPP");

my $xpc = XML::LibXML::XPathContext->new;
$xpc->registerNs('', 'jabber:client');
$xpc->registerNs('cl', 'jabber:client');

my $handler = XML::SAX::IncrementalBuilder::LibXML->new (detach => 1);
my $x = XML::Generator::XMPP->new(Handler => $handler, XPC => $xpc, Server => 'jabber.thuis');

my $client = 'cl';
$x->start;
isa_ok($handler->get_node, 'XML::SAX::IncrementalBuilder::LibXML::Document', 'first node');

my $node = $handler->get_node;
isa_ok($node, 'XML::SAX::IncrementalBuilder::LibXML::Element', 'second node');
is($node->nodeName, 'stream:stream', 'nodename is correct');
is($handler->get_node, undef, 'no more nodes for now');

$x->end;
$node = $handler->get_node;
isa_ok($node, 'XML::SAX::IncrementalBuilder::LibXML::Element', 'end node');
is($node->nodeName, 'stream:stream', 'nodename is correct');
is($node->toString, '</stream:stream>', 'stringifies ok');
is($handler->get_node, undef, 'no more nodes');

