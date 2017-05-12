use strict;
use warnings;
use Test::More;
use Test::Warnings qw(warnings);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

my $cdata_string = q{Strunk &
    white};

my $doc = XML::LibXML->createDocument();
my $node = XML::LibXML::Element->new('Top');
my $cdata = $doc->createCDATASection($cdata_string);
$doc->addChild($node);
$node->addChild($cdata);

my @warnings = warnings {
	XML::LibXML::PrettyPrint
		-> new(indent_string => "\t")
		-> pretty_print($doc)
};

is_deeply(\@warnings, [], 'Should not warn on CDATA');
is($cdata->data, $cdata_string, 'CDATA contents should be left untouched.');

done_testing;