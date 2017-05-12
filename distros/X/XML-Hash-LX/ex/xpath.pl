#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use XML::LibXML;
use XML::Hash::LX;
use Data::Dumper;

my $xml = do 'xml.pl';

# parse in common way
my $doc = XML::LibXML->new->parse_string($xml);
my $xp  = XML::LibXML::XPathContext->new($doc);
$xp->registerNs('rss', 'http://purl.org/rss/1.0/');

# then process xpath
for ($xp->findnodes('//rss:item')) {
	# and convert to hash concrete nodes
	print Dumper+xml2hash($_);
}
