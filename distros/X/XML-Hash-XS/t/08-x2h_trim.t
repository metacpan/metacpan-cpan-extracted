package main;
use strict;
use warnings;

use Test::More tests => 5;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        xml2hash(" \r\n\t<root>boom</root>"),
        'boom',
        'ignore leading white spaces',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", keep_root => 1)),
$xml_decl_utf8
<root>
    <cdata1>  <![CDATA[\n\t  cdata1\n\t   ]]>  </cdata1>
    <cdata2>  <![CDATA[ ]]>  </cdata2>
    <text> text\n \n</text>
</root>
XML
        Dumper({
root => {
    cdata1 => "\n\t  cdata1\n\t   ",
    cdata2 => " ",
    text   => " text\n \n",
},
}),
        'if the trim is off',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", keep_root => 1, trim => 1)),
$xml_decl_utf8
<root>
    <cdata1>  <![CDATA[\n\t  cdata1\n\t   ]]>  </cdata1>
    <cdata2>  <![CDATA[ ]]>  </cdata2>
    <text> text\n \n</text>
</root>\r\n
XML
        Dumper({
root => {
    cdata1 => 'cdata1',
    cdata2 => '',
    text   => 'text',
},
}),
        'if the trim is on',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", trim => 1)),
$xml_decl_utf8
<root>
    <text> </text>
</root>\r\n
XML
        Dumper({ text   => '' }),
        'when element contains only spaces and trim is on',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML", trim => 0)),
$xml_decl_utf8
<root>
    <text> </text>
</root>\r\n
XML
        Dumper({ text   => ' ' }),
        'when element contains only spaces and trim is off',
    ;
}
