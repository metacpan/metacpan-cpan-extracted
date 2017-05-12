#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;
use XML::LibXML;

my $xsd_element = qq!<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
<xs:simpleType name="DocumentType2Code">
    <xs:restriction base="xs:string">
      <xs:enumeration value="MSIN"/>
      <xs:enumeration value="CNFA"/>
      <xs:enumeration value="DNFA"/>
      <xs:enumeration value="CINV"/>
      <xs:enumeration value="CREN"/>
      <xs:enumeration value="DEBN"/>
      <xs:enumeration value="HIRI"/>
      <xs:enumeration value="SBIN"/>
      <xs:enumeration value="CMCN"/>
      <xs:enumeration value="SOAC"/>
      <xs:enumeration value="DISP"/>
    </xs:restriction>
  </xs:simpleType>
</xs:schema>!;

my ($node)  = XML::LibXML->new->parse_string( $xsd_element )->getDocumentElement->getElementsByTagName( 'xs:simpleType' );
my $element = TypeLibrary::FromXSD::Element->new( $node );

my $check   = q*declare DocumentType2Code =>
    as enum ['MSIN','CNFA','DNFA','CINV','CREN','DEBN','HIRI','SBIN','CMCN','SOAC','DISP'];*;
is $element->type, $check;

done_testing(); 
