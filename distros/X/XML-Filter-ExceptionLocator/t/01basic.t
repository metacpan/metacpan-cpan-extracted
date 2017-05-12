#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok('XML::Filter::ExceptionLocator') }

use XML::SAX::ParserFactory;

my $filter = XML::Filter::ExceptionLocator->new();
isa_ok($filter, 'XML::Filter::ExceptionLocator');
my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
ok($parser);

# nothing happening
eval { $parser->parse_uri('t/ok.xml') };
is($@, "");

