#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;
use XML::LibXML;

my $xsd_element = qq!<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
<xs:simpleType name="EurMax9Amount_SimpleType">
    <xs:restriction base="xs:decimal">
      <xs:minInclusive value="0.01"/>
      <xs:fractionDigits value="2"/>
      <xs:totalDigits value="11"/>
      <xs:maxInclusive value="999999999.99"/>
    </xs:restriction>
  </xs:simpleType>
</xs:schema>!;

my ($node)  = XML::LibXML->new->parse_string( $xsd_element )->getDocumentElement->getElementsByTagName( 'xs:simpleType' );
my $element = TypeLibrary::FromXSD::Element->new( $node );

my $check   = q*declare EurMax9Amount_SimpleType =>
    as Num,
    where {
        ($_ >= 0.01) && 
        (length( (split /\./, $_)[1] ) == 2) && 
        (tr/0123456789// == 11) && 
        ($_ <= 999999999.99)
    };*;
is $element->type, $check;

done_testing(); 
