package main;
use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash('<root a="abc&#160;def&amp;&apos;&lt;&gt;&quot;"/>', utf8 => 0)),
        Dumper({ a => "abc\302\240def&\'<>\"" }),
        'references in the attribute',
    ;
}

{
    is
        xml2hash('<root>&amp;abc&#160;def&amp;&lt;&gt;&quot;&apos;</root>', utf8 => 0),
        "&abc\302\240def&<>\"'",
        'references in the content',
    ;
}
