package main;
use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash("<root><node> </node><node_with_attr attr=\" \"/></root>", suppress_empty => 0)),
        Dumper({node => ' ', node_with_attr => {attr => ' '}}),
        'don`t suppress empty nodes',
    ;
}

{
    is
        Dumper(xml2hash("<root><node> </node><node_with_attr attr=\" \"/></root>", suppress_empty => '')),
        Dumper({node => '', node_with_attr => {attr => ''}}),
        'suppress empty nodes to empty string',
    ;
}

{
    is
        Dumper(xml2hash("<root><node> </node><node_with_attr attr=\" \"/></root>", suppress_empty => undef)),
        Dumper({node => undef, node_with_attr => {attr => undef}}),
        'suppress empty nodes to undefined value',
    ;
}
