#!/usr/bin/perl -w

package eBay::API::XML::RequestDataType;

use strict;

use Exporter;
use eBay::API::XML::DataType::AbstractRequestType;
our @ISA = ('Exporter'
		, 'eBay::API::XML::DataType::AbstractRequestType');

my @gaProperties = (  );
push @gaProperties, 
  @{eBay::API::XML::DataType::AbstractRequestType::getPropertiesList()};

my @gaAttributes = ( ['xmlns', 'xs:string', '', ''] );  
push @gaAttributes, 
  @{eBay::API::XML::DataType::AbstractRequestType::getAttributesList()};

sub new {
  my $classname = shift;
  my %args = @_;

  my $self = $classname->SUPER::new(%args);

  $self->{'xmlns'} = 'urn:ebay:apis:eBLBaseComponents';

  return $self;
}

sub getPropertiesList {
  my $self = shift;
  return \@gaProperties;
}

sub getAttributesList {
  my $self = shift;
  return \@gaAttributes;
}

1;
