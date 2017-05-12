#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

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

dies_ok {
	$parser->parse_file(\*DATA)
} "can't parse from filehandle";

dies_ok {
	$parser->parse_done;
} "can't parse_done without having started";

my @lines = <DATA>;

$parser->parse_string(shift @lines);

is($handler->{seen}{start_element}, 1, "parsed one elem");
ok(!$handler->{seen}{end_element}, "nothing ended yet");

dies_ok {
	$parser->parse_start;
} "can't start after having started";

$parser->parse_string(shift @lines);

is($handler->{seen}{start_element}, 3, "two elements started");
is($handler->{seen}{end_element}, 2, "two closed");

$parser->parse_string(shift @lines);

is($handler->{seen}{start_element}, 4, "one more opened");
ok($handler->{seen}{characters}, "at least some character data by now");
is($handler->{seen}{end_element}, 3, "one more closed");

my $line = shift @lines;

$parser->parse_string(substr($line, 0, 3, '')); # "</x"

is($handler->{seen}{end_element}, 3, "nothing closed after adding half a close tag");

$parser->parse_string($line);

is($handler->{seen}{end_element}, $handler->{seen}{start_element}, "root element closed");

$parser->parse_done;

ok($handler->{seen}{end_document}, "document ended");

lives_ok {
	$parser->parse_start;
} "now that we're done we can start a new parse";

__DATA__
<xml>
	<foo/><gorch/>
	<bar>ding</bar>
</xml>
