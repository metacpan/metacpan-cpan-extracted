#!/bin/perl -w

use XML::XPath;
use Test::More;

# Some example XML. Note that the items are identical except for the
# namespaces ('namespace1' vs 'namespace2').

my $xml1 = <<'EOXML';
<ns0:first xmlns:ns0="namespace0">
           <ns1:second xmlns:ns1="namespace1">
                       <ns1:second-item>foo</ns1:second-item>
                        <ns1:second-item>bar</ns1:second-item>
                        </ns1:second>
</ns0:first>
EOXML

my $xml2 = <<'EOXML';
<ns0:first xmlns:ns0="namespace0">
           <ns2:second xmlns:ns2="namespace2">
                       <ns2:second-item>foo</ns2:second-item>
                        <ns2:second-item>bar</ns2:second-item>
                        </ns2:second>
</ns0:first>
EOXML

# This will work as expected, but will also populate the cache
# with the parser for $xpath1.

my $xpath1 = XML::XPath->new( xml => $xml1 );
$xpath1->set_namespace( "a", "namespace0" );
$xpath1->set_namespace( "b", "namespace1" );

my @nodes = $xpath1->findnodes( "/a:first/b:second/b:second-item" );
is(scalar(@nodes), 2);

my $xpath2 = XML::XPath->new( xml => $xml2 );
$xpath2->set_namespace( "a", "namespace0" );
$xpath2->set_namespace( "b", "namespace2" );
@nodes = $xpath2->findnodes( "/a:first/b:second/b:second-item" );

is(scalar(@nodes), 2);

done_testing();
