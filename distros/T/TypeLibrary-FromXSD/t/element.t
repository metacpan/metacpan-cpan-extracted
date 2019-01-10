#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use XML::LibXML;
use TypeLibrary::FromXSD;
use TypeLibrary::FromXSD::Element;

{
    my $error;
    eval {
        my $element = TypeLibrary::FromXSD::Element->new;
    } or $error = $@;

    like $error, qr/Missing required arguments: base, name/;
}

{
    my $element = TypeLibrary::FromXSD::Element->new( name => 'Test', base => 'Str' );
    is $element->name, 'Test';
    is $element->base, 'Str';
    is $element->orig_base, undef;
}

{
    my $error;
    eval {
        my $element = TypeLibrary::FromXSD::Element->new('Element', validate => {} );
    } or $error = $@;

    like $error, qr/Missing required arguments: base, name/;
}

{
    my $error;
    eval {
        my $element = TypeLibrary::FromXSD::Element->new({}, validate => {} );
    } or $error = $@;

    like $error, qr/Can't call method "isa" /;
}

{
    my $error;
    eval {
        my $element = TypeLibrary::FromXSD::Element->new([], validate => {} );
    } or $error = $@;

    like $error, qr/Can't call method "isa" /;
}

{

    my $obj = bless {}, 'MyTest';

    my $error;
    eval {
        my $element = TypeLibrary::FromXSD::Element->new($obj, validate => {} );
    } or $error = $@;

    like $error, qr/Missing required arguments: base, name/;
}

{
    my $xml       = q~<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
  <xs:simpleType name="ISODateTime">
    <xs:restriction base="xs:hallo"/>
  </xs:simpleType>
</xs:schema>
~;
    my $tree      = XML::LibXML->load_xml( string => $xml )->getDocumentElement;
    my @typeNodes = $tree->getElementsByTagName('xs:simpleType');

    my $element = TypeLibrary::FromXSD::Element->new($typeNodes[0], validate => {} );

    is $element->name, 'ISODateTime';
}

{
    my $xml       = q~<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
  <xs:simpleType name="ISODateTime">
    <xs:restriction base="xs:date"/>
  </xs:simpleType>
</xs:schema>
~;
    my $tree      = XML::LibXML->load_xml( string => $xml )->getDocumentElement;
    my @typeNodes = $tree->getElementsByTagName('xs:simpleType');

    my $element = TypeLibrary::FromXSD::Element->new($typeNodes[0], validate => {} );

    is $element->name, 'ISODateTime';
}

done_testing();
