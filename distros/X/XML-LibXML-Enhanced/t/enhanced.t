#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw(no_plan);

use XML::LibXML::Enhanced qw(parse_xml_string parse_xml_file parse_xslt_file);

# Perl version 5.8.1 and above have random hash key order; this
# breaks some of the tests.  TO fix this (for tests only), set
# PERL_HASH_SEED to 0.  (See perlrun.) Pre-5.8.1. version of Perl
# don't randomise hash keys, but the order of different platforms is
# unpredictable anyway.

my $HASH_ORDER_UNPREDICTABLE = (($] < 5.008001) || (!defined $ENV{PERL_HASH_SEED})) ? 1 : 0;
my $HASH_ORDER_REASON = "hash order unpredictable in this version, or PERL_HASH_SEED not 0";

my $xml = XML::LibXML::Singleton->instance;

{
    my $tmp = XML::LibXML::Singleton->instance;
    
    is($xml, $tmp, "singleton-ness");
}

{
    my $doc = $xml->parse_string(<<END);
    <root>
    <greeting/>
    </root>
END

    isa_ok($doc, "XML::LibXML::Document");

    my $hash = {
	name => "Michael",
	age => 27,
    };

    $doc->getDocumentElement->appendHash($hash, 0);

    my $expected = $xml->parse_string(<<END);
<?xml version="1.0"?>
    <root>
    <greeting/>
    <name>Michael</name><age>27</age></root>
END

    isa_ok($expected, "XML::LibXML::Document");
    
    SKIP: {
	
	skip $HASH_ORDER_REASON, 1 if $HASH_ORDER_UNPREDICTABLE;

	ok($doc->toStringC14N eq $expected->toStringC14N, "appendHash(., 1)");
	
    }
}

{
    my $doc = $xml->parse_string("<root/>");
    
    my $hash = { greeting => "Hullo, World!" };

    $doc->getDocumentElement->appendHash($hash);
    
    my $res = $doc->getDocumentElement->toHash(1);
    
    ok(eq_hash($res, $hash), "toHash(0)");
    
}

{
    my $doc = $xml->parse_string("<root/>");
    
    my $hash = { 
	name => "Michael",
	email => 'mjs@beebo.org',
	phone => "+44 78 21 18 90 49"
    };
    
    my $expected = $xml->parse_string('<root><row><email>mjs@beebo.org</email><name>Michael</name><phone>+44 78 21 18 90 49</phone></row></root>');

    $doc->getDocumentElement->appendRow($hash);
    
    SKIP: {
	
	skip $HASH_ORDER_REASON, 1 if $HASH_ORDER_UNPREDICTABLE;

	ok($expected->toStringC14N eq $doc->toStringC14N, "appendRow()");
	
    }
}

{
    my $doc = $xml->parse_string("<root/>");
    
    my $museum = "<cite>The V&amp;A</cite>";

    my $hash = {
	museum => $museum,
    };
    
    my $expected = $xml->parse_string('<root><museum><cite>The V&amp;A</cite></museum></root>');
    
    $doc->getDocumentElement->appendHash($hash, 0);
    
    SKIP: {
	skip $HASH_ORDER_REASON, 1 if $HASH_ORDER_UNPREDICTABLE;

	ok($expected->toStringC14N eq $doc->toStringC14N, "appendHash(., 1)");
    }
    
    my $res = $doc->getDocumentElement->toHash;
    
    is($res->{museum}, $museum);
}

{
    my $doc = $xml->parse_string("<root/>");
    
    my $hash = {
	s => "<foo>",
    };
    
    my $expected = q{<!--NOT BALANCED XML-->};

    $doc->getDocumentElement->appendHash($hash, 0);
    
    my $res = $doc->getDocumentElement->toHash;
    
    is($res->{s}, $expected, "unbalanced XML value chunk");
}

{
    my $doc = $xml->parse_string("<root/>");
    
    my $expected = "M&Ms <em>sells</em>";

    my $hash = {
	s => $expected,
    };
    
    $doc->getDocumentElement->appendHash($hash, 1);
    
    my $res = $doc->getDocumentElement->toHash(1);
    
    is($res->{s}, $expected);
}

{
    my $doc = parse_xml_string(qq{<page title="Welcome to T&amp;A!"/>});
    
    my $res = $doc->getDocumentElement->toAttributeHash;
    my $expected = "Welcome to T&A!";

    is($res->{title}, $expected);
}

{
    my $doc = parse_xml_string(qq{<page/>});
    
    my $res = $doc->getDocumentElement->appendAttributeHash({
        title => "Welcome to T&A!",
	date => "Today"
    });
    
    my $expected = parse_xml_string(q{<page date="Today" title="Welcome to T&amp;A!"/>});

    is($doc->toStringC14N, $expected->toStringC14N);
}    
								
{
    my $doc = parse_xml_string(qq{<page/>});
    
    my $expected1 = "Welcome to T&A!";
    my $expected2 = "Today";

    $doc->getDocumentElement->appendAttributeHash({
        title => "FOOBAR",
    });
    
    $doc->getDocumentElement->appendAttributeHash({
        date => $expected2,
    });
    
    $doc->getDocumentElement->appendAttributeHash({
        title => $expected1,
    });
    
    my $res = $doc->getDocumentElement->toAttributeHash;
    
    is($res->{title}, $expected1);
    is($res->{date}, $expected2);
}
    
{
    my $doc = parse_xml_string("<root/>");
    
    my $root = $doc->getDocumentElement;
    
    $root->appendHash({ name => '' });
    
    ok($doc->toString !~ /BALANCED/);
}

{
    my $doc = parse_xml_string("<root/>");
    
    my $root = $doc->getDocumentElement;
    
    $root->appendHash({ FirstName => '' });
    
    ok($doc->toString =~ /FirstName/);
}

{
    my $doc = parse_xml_string("<root/>");
    
    my $root = $doc->getDocumentElement;
    
    $root->appendHash([
	a => undef,
	b => undef,
	c => undef,
	d => undef,
	a => undef,
	e => undef,
    ]);
    
    my $expected = parse_xml_string("<root><a/><b/><c/><d/><a/><e/></root>");
    
    is($doc->toString, $expected->toString);
}

{
    my $doc = parse_xml_string('<root><id>0</id><email>bob@bob.com</email></root>');

    my $hash = $doc->getDocumentElement->toHash;
    
    is($hash->{id}, "0");
    is($hash->{email}, 'bob@bob.com');
    ok(!exists $hash->{foo});
}

{
    my $file1 = -e "t/test1.xml" ? "t/test1.xml" : "test1.xml";
    my $file2 = -e "t/test2.xml" ? "t/test2.xml" : "test2.xml";
    

    my ($doc1, $doc2) = parse_xml_file($file1, $file2);
    
    isa_ok($doc1, "XML::LibXML::Document");
    isa_ok($doc2, "XML::LibXML::Document");
    
    my $doc3 = parse_xml_file($file1);
    
    isa_ok($doc3, "XML::LibXML::Document");
}

{
    my $file1 = -e "t/test1.xsl" ? "t/test1.xsl" : "test1.xsl";
    my $file2 = -e "t/test2.xsl" ? "t/test2.xsl" : "test2.xsl";

    my ($doc1, $doc2) = parse_xslt_file($file1, $file2);
    
    isa_ok($doc1, "XML::LibXSLT::Stylesheet");
    isa_ok($doc2, "XML::LibXSLT::Stylesheet");
}

{
    my $doc1 = parse_xml_string("<root/>");
    my $doc2 = parse_xml_string("<root><NAME>Daniel</NAME></root>");
    
    $doc1->documentElement->appendHash({ NAME => "Daniel" });
    
    is($doc1->toString, $doc2->toString);
}
