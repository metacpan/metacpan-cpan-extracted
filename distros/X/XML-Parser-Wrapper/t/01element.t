#!/usr/bin/env perl -w
# $Id: 01element.t,v 1.1 2005/05/06 01:58:08 don Exp $

use strict;

# main
{
    use Test::More tests => 5;
    
    use XML::Parser::Wrapper;

    my $xml = q{<?xml version="1.0" encoding="utf-8"?><!DOCTYPE greeting SYSTEM "hello.dtd"><store><field name="" class="Hash" id="a"><field name="array1" class="Array" id="b"><element name="" class="String" id="c">data with ]]&gt;</element><element name="" class="String" id="d">another element</element></field><field name="test1" class="String" id="e">val1</field><field name="test2" class="String" id="f">val2</field><field name="test3" class="String" id="g">val&gt;3</field></field></store>};

    my $root = XML::Parser::Wrapper->new($xml);

    ok(($root->name eq 'store'), 'top name check');
    ok(($root->kid('field')->attribute('id') eq $root->kids('field')->[0]->attribute('id')), 'attr check');
    ok(($root->kid('field')->kid('field')->kid('element')->text eq 'data with ]]>'), 'cdata');

    my $expected_xml_decl = {
                             'version' => '1.0',
                             'standalone' => undef,
                             'encoding' => 'utf-8'
                            };
    my $expected_doctype = {
                            'pubid' => undef,
                            'sysid' => 'hello.dtd',
                            'name' => 'greeting',
                            'internal' => ''
                           };

    my $xml_decl = $root->get_xml_decl;
    my $doctype = $root->get_doctype;

    is_deeply($xml_decl, $expected_xml_decl, 'xml decl');
    is_deeply($doctype, $expected_doctype, 'doctype');
}

exit 0;

###############################################################################
# Subroutines

