#!/usr/bin/perl -w
use strict;

# $Id: test_xml_xpath_and_xml_dom_xpath.t,v 1.2 2005/03/07 08:39:13 mrodrigu Exp $


use Test::More tests => 1;
use XML::DOM::XPath;

unless(eval{require XML::XPath}) { ok(1); exit; }

import XML::XPath; 

my $xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<school>
<class>
<student name="joe"/>
<student/>
</class>
</school>
EOF

my $xp = XML::XPath->new($xml);		
my $exp = '/school/class/student/@name';				
my $nodeSet = $xp->find($exp);
is( $nodeSet->size(), 1, "using XML::XPath and XML::DOM::XPath");


