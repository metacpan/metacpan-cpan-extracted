package main;
use strict;
use warnings;

use Test::More tests => 4;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        xml2hash("<cdata><![CDATA[\n\t  abcde!@#\$%^&*<>\n\t   ]]></cdata>"),
        "\n\t  abcde!\@#\$%^&*<>\n\t   ",
        'use special symbols',
    ;
}

{
    is
        xml2hash("<cdata><![CDATA[ [ abc ] ]> ]]]]]]></cdata>"),
        ' [ abc ] ]> ]]]]',
        'terminate section',
    ;
}

{
    is
        xml2hash("<cdata><![CDATA[ ]]]></cdata>"),
        ' ]',
        'terminate section2',
    ;
}

{
    is
        xml2hash("<cdata><![CDATA[]]></cdata>"),
        '',
        'empty section',
    ;
}
