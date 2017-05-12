#!/usr/bin/perl

# pretty much the example test from L<XML::SAX>

use Test::More tests => 3;

use XML::SAX;
use XML::SAX::PurePerl::DebugHandler;

XML::SAX->add_parser(q(XML::SAX::Expat::Incremental));

local $XML::SAX::ParserPackage = 'XML::SAX::Expat::Incremental';

isa_ok(
	my $handler = XML::SAX::PurePerl::DebugHandler->new(),
	"XML::SAX::PurePerl::DebugHandler",
);

isa_ok(
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler),
	"XML::SAX::Expat::Incremental",
);

$parser->parse_string("<tag/>");

ok($handler->{seen}{start_element}, "parsed something");

