#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;
use XML::LibXML;

my $xsd_element = qq!<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:sepade:xsd:pain.001.001.02" targetNamespace="urn:sepade:xsd:pain.001.001.02" elementFormDefault="qualified">
<xs:simpleType name="ISODate">
    <xs:restriction base="xs:date"/>
  </xs:simpleType>
</xs:schema>!;

my ($node)  = XML::LibXML->new->parse_string( $xsd_element )->getDocumentElement->getElementsByTagName( 'xs:simpleType' );

{
    my $element = TypeLibrary::FromXSD::Element->new( $node );

    my $check   = q*declare ISODate =>
    as Str,
    where {
        ($_ =~ m{\A-?[0-9]{4,}-[0-9]{2}-[0-9]{2}(?:Z|[-+]?[0-2][0-9]:[0-5][0-9])?\z})
    };*;
    is $element->type, $check;
}


{
    my $element = TypeLibrary::FromXSD::Element->new( $node, validate => { date => 'validate_date' } );

    my $check   = q*declare ISODate =>
    as Str,
    where {
        ($_ =~ m{\A-?[0-9]{4,}-[0-9]{2}-[0-9]{2}(?:Z|[-+]?[0-2][0-9]:[0-5][0-9])?\z}) && 
        (validate_date($_))
    };*;
    is $element->type, $check;
}


done_testing(); 
