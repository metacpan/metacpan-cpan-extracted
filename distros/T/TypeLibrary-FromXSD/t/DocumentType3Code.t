#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;
use XML::LibXML;

my $xsd_element = qq!<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
<xs:simpleType name="DocumentType3Code">
    <xs:restriction base="xs:string">
      <xs:enumeration value="RADM"/>
      <xs:enumeration value="RPIN"/>
      <xs:enumeration value="FXDR"/>
      <xs:enumeration value="DISP"/>
      <xs:enumeration value="PUOR"/>
      <xs:enumeration value="SCOR"/>
    </xs:restriction>
  </xs:simpleType>
</xs:schema>!;

my ($node)  = XML::LibXML->new->parse_string( $xsd_element )->getDocumentElement->getElementsByTagName( 'xs:simpleType' );
my $element = TypeLibrary::FromXSD::Element->new( $node );

my $check   = q*declare DocumentType3Code =>
    as enum ['RADM','RPIN','FXDR','DISP','PUOR','SCOR'];*;
is $element->type, $check;

done_testing(); 
