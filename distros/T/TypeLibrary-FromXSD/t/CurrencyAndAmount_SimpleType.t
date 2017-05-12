#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;
use XML::LibXML;

my $xsd_element = qq!<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
<xs:simpleType name="CurrencyAndAmount_SimpleType">
    <xs:restriction base="xs:decimal">
      <xs:minInclusive value="0"/>
      <xs:fractionDigits value="5"/>
      <xs:totalDigits value="18"/>
    </xs:restriction>
  </xs:simpleType>
</xs:schema>!;

my ($node)  = XML::LibXML->new->parse_string( $xsd_element )->getDocumentElement->getElementsByTagName( 'xs:simpleType' );
my $element = TypeLibrary::FromXSD::Element->new( $node );

my $check   = q*declare CurrencyAndAmount_SimpleType =>
    as Num,
    where {
        ($_ >= 0) && 
        (length( (split /\./, $_)[1] ) == 5) && 
        (tr/0123456789// == 18)
    };*;
is $element->type, $check;

done_testing(); 
