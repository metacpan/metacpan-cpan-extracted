# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Assigning::Serializer;

use strict;
use warnings;

use LS::ID;

my $SCHEMA_TYPES_URI = 'http://www.omg.org/LSID/2003/Standard/Assigning/WSDL/SchemaTypes';

my $SCHEMA_TYPES_PREF = 'ast';

#
# SOAP::Lite doesn't handle complex types
#
# I'm not even trying to be elegant
#

sub SOAP::Serializer::as_authorityNamespaceList {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

        my $children = [];

        foreach(@{ $value }) {

		push @{ $children }, $self->as_authorityNamespace($_, 'authorityNamespace', 'xsd:authorityNamespace', {});
        }

        return [ ($name || 'authorityNamespaceList'), $attr, $children ];
}

sub SOAP::Serializer::as_authorityNamespace {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	my $children = [];

	$attr->{'xmlns:' . $SCHEMA_TYPES_PREF} = $SCHEMA_TYPES_URI;

		my ($authority) = keys(%{ $value });
		my $namespace = $value->{$authority};

	push @{ $children }, $self->as_authority( $authority, 'authority', 'xsd:string', {} ), $self->as_namespace( $namespace, 'namespace', 'xsd:string', {} );

	return [ "$SCHEMA_TYPES_PREF:" . ($name || 'authorityNamespace'), $attr, $children ];
}

sub SOAP::Serializer::as_authority {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	$attr->{'xmlns:' . $SCHEMA_TYPES_PREF} = $SCHEMA_TYPES_URI;

	return [ "$SCHEMA_TYPES_PREF:" . ($name || 'authority'), $attr, $value ];
}

sub SOAP::Serializer::as_namespace {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	$attr->{'xmlns:' . $SCHEMA_TYPES_PREF} = $SCHEMA_TYPES_URI;

	return [ "$SCHEMA_TYPES_PREF:" . ($name || 'namespace'), $attr, $value ];
}

sub SOAP::Serializer::as_propertyNameList {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

        my $children = [];

        foreach(@{ $value }) {

		push @{ $children }, $self->as_propertyName($_, 'propertyName', 'xsd:string', {});
        }

        return [ ($name || 'propertyNameList'), $attr, $children ];
}

sub SOAP::Serializer::as_propertyName {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	$attr->{'xmlns:ast'} = $SCHEMA_TYPES_URI;

	return [ "$SCHEMA_TYPES_PREF:" . ($name || 'propertyName'), $attr, $value ];
}

sub SOAP::Serializer::as_LSIDPatternList {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	my $seq = "0";
	my $children = [];

	#$attr->{'xmlns:ast'} = $SCHEMA_TYPES_URI;

	foreach(@{ $value }) {

		$attr->{'id'} = $seq;

		push @{ $children }, $self->as_LSIDPattern($_, 'LSIDPattern', 'xsd:string', { id=> $seq });

		$seq++;
	}

	return [ ($name || 'LSIDPatternList'), $attr, $children ];
}

sub SOAP::Serializer::as_LSIDPattern {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	my $ns_pre = 'xmlns:ast' . $attr->{'id'};

	$attr->{ $ns_pre } = $SCHEMA_TYPES_URI;

	$ns_pre = $SCHEMA_TYPES_PREF . $attr->{'id'} . ':';

	return [ ( $ns_pre . ($name || 'LSIDPattern') || 'LSIDPattern'), $attr, $value ];
}

sub SOAP::Serializer::as_LSIDList {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	my $children = [];
	
        foreach(@{ $value }) {

		push @{ $children }, $self->as_lsid($_, 'lsid', 'xsd:anyURI', {});
        }

        return [ ($name || 'LSIDList'), $attr, $children ];
}

sub SOAP::Serializer::as_lsid {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

        return [ ($name || 'lsid'), $attr, $value ];
}

sub SOAP::Serializer::as_propertyList {

        my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	my $seq = "0";

	my $children = [];

        foreach(@{ $value } ) {

                my $nv = (keys(%{ $_ }))[0];

		push @{ $children }, $self->SOAP::Serializer::as_property( { $nv=> $_->{ $nv } } , 
									    'property', 
									    'xsd:property', 
									    { id=> $seq });

		$seq++;
        }

        return [ ($name || 'propertyList'), $attr, $children ];
}

sub SOAP::Serializer::as_property {

	my $self = shift;

        my ($value, $name, $type, $attr) = @_;

        my $xml;

	my $ns_pre = 'xmlns:ast' . $attr->{'id'};

	$attr->{ $ns_pre } = $SCHEMA_TYPES_URI;

	$ns_pre = $SCHEMA_TYPES_PREF . $attr->{'id'} . ':' ;

        foreach(keys(%{ $value }) ) {

                $xml .= "<${ns_pre}name>$_</${ns_pre}name>";
                $xml .= "<${ns_pre}value>" . $value->{$_} . "</${ns_pre}value>";
        }

        return [ $ns_pre . ($name || 'property'), $attr, $xml  ] ;
}

sub SOAP::Serializer::as_value {

	my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	return [ ] ;
}

sub SOAP::Serializer::as_name {

	my $self = shift;

        my ($value, $name, $type, $attr) = @_;

	return [ ] ;
}

1;

__END__
