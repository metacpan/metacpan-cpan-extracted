# Copyright (c) 2002 Robert Joop <yaph-070708@timesink.de>
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

package X500::DN;

use 5.6.1; # the "our" keyword below needs it
use strict;
use Carp;
use Parse::RecDescent 1.80;
use X500::RDN;

our $VERSION = '0.29';

my $rfc2253_grammar = q {
startrule: DistinguishedName /^\\Z/ { new X500::DN (reverse (@{$item[1]})); }
DistinguishedName: name(?) { @{$item[1]} > 0 ? $item[1][0] : []; }
name: nameComponent(s /[,;]\\s*/)
nameComponent: attributeTypeAndValue(s /\\s*\\+\\s*/) { new X500::RDN (map { @$_ } @{$item[1]}); }
attributeTypeAndValue: attributeType /\\s*=\\s*/ attributeValue { [ @item[1,3] ]; }
attributeType: Alpha keychar(s?) { join ('', $item[1], @{$item[2]}); }
  | oid
keychar: Alpha | Digit | '-'
#oid: rfc1779oidprefix(?) Digits(s /\\./) { join ('.', @{$item[2]}) }
#rfc1779oidprefix: /oid\\./i
oid: Digits(s /\\./) { join ('.', @{$item[1]}) }
Digits: Digit(s) { join ('', @{$item[1]}); }
attributeValue: string
string: (stringchar | pair)(s) { join ('', @{$item[1]}); }
  | '#' hexstring { $item[2] }
  | '"' (pair | quotechar)(s) '"' { join ('', @{$item[2]}); }
quotechar: /[^"]/
special: /[,=+<>#; ]/
pair: '\\\\' ( special | '\\\\' | '"' | hexpair ) { $item[2] }
stringchar: /[^,=+<>#;\\\\"]/
hexstring: hexpair(s) { join ('', @{$item[1]}); }
hexpair: /[0-9A-Fa-f]{2}/ { chr (hex ($item[1])) }
Alpha: /[A-Za-z]/
Digit: /[0-9]/
};

#$::RD_TRACE = 1;
#$::RD_HINT = 1;

local $::RD_AUTOACTION = q{ $item[1] };
local $Parse::RecDescent::skip = undef;
my $parser = new Parse::RecDescent ($rfc2253_grammar) or die "Bad RFC 2253 grammar!\n";

sub new
{
  my $class = shift;
  my $self = [ @_ ];
  bless $self, $class;
  return $self;
}

sub hasMultivaluedRDNs
{
  my $self = shift;
  return grep { $_->isMultivalued } @$self;
}

sub getRDN
{
  my $self = shift;
  my $i = shift;
  return $self->[$i];
}

sub getRDNs
{
  my $self = shift;
  return @$self;
}

sub ParseRFC2253
{
  my $class = shift;
  my $text = shift;
  my $self = $parser->startrule ($text);
  return $self;
}

sub ParseOpenSSL
{
  croak "use 'openssl -nameopt RFC2253' and ParseRFC2253()";
}

sub getRFC2253String
{
  my $self = shift;
  return join (', ', map { $_->getRFC2253String } reverse (@{$self}));
}

sub getX500String
{
  my $self = shift;
  return '{' . join (',', map { $_->getX500String } @{$self}) . '}';
}

sub getOpenSSLString
{
  my $self = shift;
  return join ('/', '', map { $_->getOpenSSLString } @{$self});
}

1;
