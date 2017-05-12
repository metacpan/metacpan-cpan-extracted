#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

pipe READ, WRITE;

use XML::SAX;
use XML::SAX::PurePerl::DebugHandler;

XML::SAX->add_parser(q(XML::SAX::ExpatNB));

local $XML::SAX::ParserPackage = 'XML::SAX::ExpatNB';

isa_ok(
	my $handler = XML::SAX::PurePerl::DebugHandler->new(),
	"XML::SAX::PurePerl::DebugHandler",
);

isa_ok(
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler),
	"XML::SAX::ExpatNB",
);

local $SIG{ALRM} = sub { die "Timeout!" };
alarm 1;

$parser->parse_file(\*READ);

ok(!$handler->{seen}{start_element}, "nothing parsed yet");

syswrite WRITE, "<xml";

$parser->parse_file(\*READ);

ok(!$handler->{seen}{start_element}, "nothing parsed yet");

syswrite WRITE, "/>";

$parser->parse_file(\*READ);

ok($handler->{seen}{start_element}, "parsed something");

alarm 0;
