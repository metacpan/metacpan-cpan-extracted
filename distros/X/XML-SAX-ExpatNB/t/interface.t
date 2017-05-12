#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
BEGIN {
	eval { use Sub::Override };
	plan skip_all => "need Sub::Override for these tests" if $@;
}

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

my $o = Sub::Override->new;

my ($pb, $pbonce);
$o->replace("XML::SAX::ExpatNB::_parse_bytestream" => sub {
	$pb++;
});
$o->replace("XML::SAX::ExpatNB::_parse_bytestream_once" => sub {
	$pbonce++;
});

dies_ok {
	$parser->parse_string("<xml/>");
} "Silly rabbit, NB is for filehandles";

$parser->parse_file(\*DATA);

ok($pb, "_parse_bytestream called");

$parser->parse_file(\*DATA, ReadOnce => 1);

ok($pbonce, "_parse_bytestream_once");
undef $pbonce;

$parser->parse_once(\*DATA, 123);

ok($pbonce, "_parse_bytestream_once convenience");

__DATA__
<xml>
	<tag/>
</xml>
