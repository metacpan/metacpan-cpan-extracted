#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::XML;
use Test::Exception;

use Path::Class;
use URI;
use URI::file;

use ok 'XML::LibXSLT::Easy';
use ok 'XML::LibXSLT::Easy::Batch';

my $xmldir = file(__FILE__)->parent->subdir("xml");
my $xmlfile = $xmldir->file("foo.xml");
my $xslfile = $xmldir->file("foo.xsl");
my $outfile = $xmldir->file("foo.html");

my $t = XML::LibXSLT::Easy->new;

isa_ok( $t, "XML::LibXSLT::Easy" );

isa_ok( $t->xml, "XML::LibXML" );

isa_ok( $t->xslt, "XML::LibXSLT" );

my $exp_xml = <<XML;
<?xml version="1.0"?>
<div class="blart">
    <div id="panel_0" class="upper"><h3>foo</h3></div>
    <div id="panel_1" class="upper"><h3>bar</h3></div>
</div>
XML

{
    my $xml = $t->process( xml => $xmlfile, xsl => $xslfile );

    ok($xml, "got some xml, Path::Class");

    is_xml( $xml, $exp_xml, "processed correctly" );
}

{
    my $xml = $t->process( xml => URI::file->new($xmlfile), xsl => $xslfile );

    ok($xml, "got some xml, URI::file");

    is_xml( $xml, $exp_xml, "processed correctly" );
}

{
    my $xml = $t->process( xml => $xmlfile );

    ok($xml, "got some xml");

    is_xml( $xml, $exp_xml, "processed correctly according to <?xml-stylesheet>" );
}

# removed because DataURI can't be a subtype of URI (union of URI and
# URI::WithBase, not related classes)
#{
#    my $uri = URI->new("data:");
#    $uri->data(scalar $xmlfile->slurp);
#
#    throws_ok { $t->process( xml => $uri ) } qr/xml-stylesheet/, "can't get stylesheet without base";
#
#    my $xml = $t->process( xml => $uri, xsl => $xslfile );
#
#    ok($xml, "got some xml");
#
#    is_xml( $xml, $exp_xml, "processed correctly according to <?xml-stylesheet>" );
#}


my $b = XML::LibXSLT::Easy::Batch->new;

is_deeply(
    [ $b->expand( xml => $xmldir->file("*.xml") ) ],
    [ { xml => $xmlfile, xsl => $xslfile, out => $outfile } ],
    "glob expansion",
);


