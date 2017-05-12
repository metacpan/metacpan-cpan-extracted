# Copyright (c) 2002 Robert Joop <yaph-070708@timesink.de>
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

package X500::RDN;

use strict;
use Carp;

sub new
{
  my $class = shift;
  my $self = { @_ };
  bless $self, $class;
  return $self;
}

sub isMultivalued
{
  my $self = shift;
  return $self->getAttributeTypes() > 1;
}

sub getAttributeTypes
{
  my $self = shift;
  return keys (%$self);
}

sub getAttributeValue
{
  my $self = shift;
  my $type = shift;
  return $self->{$type};
}

# internal function: quote special AttributeValue characters
sub _RFC2253quoteAttributeValue
{
  my $value = shift;
  $value =~ s/([,;+"\\<>])/\\$1/g;
  $value =~ s/( )$/\\$1/g;		# space at end of string
  $value =~ s/^([ #])/\\$1/g;		# space at beginning of string
  return $value;
}

sub getRFC2253String
{
  my $self = shift;
  return join ('+', map { "$_=".&_RFC2253quoteAttributeValue ($self->{$_}); } keys (%$self));
}

sub getX500String
{
  my $self = shift;
  my $s = join (', ', map { "$_=".&_RFC2253quoteAttributeValue ($self->{$_}) } keys (%$self));
  $s = "($s)" if ($self->isMultivalued);
  return $s;
}

# internal function: quote special AttributeValue characters
sub _OpenSSLquoteAttributeValue
{
  my $value = shift;
  $value =~ s/([\\\/])/\\$1/g;
  return $value;
}

sub getOpenSSLString
{
  my $self = shift;
  croak "openssl syntax for multi-valued RDNs is unknown" if ($self->isMultivalued);
  my $key = (keys (%$self))[0];
  my $s = "$key=".&_OpenSSLquoteAttributeValue ($self->{$key});
  return $s;
}

1;
