package WebService::Cmis::Property;

=head1 NAME

WebService::Cmis::Property

Representation of a property of a cmis object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis qw(:namespaces);
use Error qw(:try);

=head1 METHODS

=over 4

=item new(%params)

=cut

sub new {
  my $class = shift;
  my %params = @_;

  #print STDERR "params: ".join(', ', map($_."=".$params{$_}, keys %params))."\n";

  # shortcut id -> propertyDefinitionId
  if (defined $params{id} && !defined $params{propertyDefinitionId}) {
    $params{propertyDefinitionId} = delete  $params{id};
  }

  my $this = bless( \%params, $class); 
  throw Error::Simple("no id for property") unless defined $this->{propertyDefinitionId};

  return $this;
}

=item toString

string representation of this property

=cut

sub toString {
  my $this = shift;

  my $val = $this->{value} || '';
  $val = join(', ', @$val) if ref($val);
  return $this->getId."=".($val);
}

=item toXml($xmlDoc)

returns an XML::LibXml::Node representing this property.
$xmlDoc is the document to allocate the xml node for.

=cut

sub toXml {
  my ($this, $xmlDoc) = @_;

  my $propElement = $xmlDoc->createElementNS(CMIS_NS, $this->getNodeName);

  foreach my $key (sort keys %$this) {
    next if $key eq 'value';
    my $val = $this->{$key};
    $propElement->setAttribute($key, $val);
  }

  # add cmis:value
  my $value = $this->getValue;
  if (ref($value) eq 'ARRAY') {
    foreach my $val (@$value) {
      my $valElement = $propElement->addNewChild(CMIS_NS, 'cmis:value');
      $valElement->addChild($xmlDoc->createTextNode($this->unparse($val)));
    }
  } else {
    my $valElement = $propElement->addNewChild(CMIS_NS, 'cmis:value');
    $valElement->addChild($xmlDoc->createTextNode($this->unparse($value)));
  }

  return $propElement;
}

=item getId

getter for propertyDefinitionId

=cut

sub getId {
  return $_[0]->{propertyDefinitionId};
}

=item getNodeName

returns the xml node name for this property

=cut

sub getNodeName {
  my $this = shift;

  my $class = ref($this);
  $class =~ s/^.*:://;

  return "cmis:property".$class;
}

=item getValue

getter for property value

=cut

sub getValue {
  return $_[0]->{value};
}

=item setValue($cmisValue) -> $perlValue

setter for property value, converting it to the specific perl representation

=cut

sub setValue {
  my ($this, $value) = @_;
  return $this->{value} = $this->parse($value);
}

=item parse($cmisValue) -> $perlValue

parses a cmis value into its perl representation. 

=cut

sub parse {
  # my ($this, $value) = @_;

  # no conversion by default
  return $_[1];
}

=item unparse($perlValue) $cmisValue

converts a perl representation back to a format understood by cmis

=cut

sub unparse {
  my ($this, $value) = @_;

  $value = $this->{value} if ref($this) && ! defined $value;

  return 'none' unless defined $value;
  return $value;
}

=item load

static helper utility to create a property object loading it from its xml
representation

=cut

sub load {
  my $xmlDoc = shift;

  my $nodeName = $xmlDoc->nodeName;
  $nodeName =~ s/^cmis:property//g;
  my $class = "WebService::Cmis::Property::".$nodeName;

  # untaint
  $class =~ /^(.*)/s;
  $class = $1;

  eval "use $class";
  if ($@) {
    throw Error::Simple($@);
  }

  # get attributes
  my %attrs = ();
  foreach my $attr (@{$xmlDoc->attributes->nodes}) {
    #print STDERR $attr->nodeName."=".$attr->value."\n";
    my $key = $attr->nodeName;
    my $val = $attr->value;
    $attrs{$key} = $val;
    $attrs{propertyDefinitionId} = $val if $key eq 'id'; # alias
  }

  my $property = $class->new(%attrs);

  # get value
  my $value;
  my @childNodes = $xmlDoc->nonBlankChildNodes;
  if (scalar(@childNodes) > 1) {
    push @{$value}, $_->string_value foreach @childNodes;
  } else {
    my $node = shift @childNodes;
    if ($node) {
      $value = $node->string_value;
    }
  }

  $property->setValue($value);

  return $property;
}

=item newBoolean(%params) -> $propertyBoolean

static helper utility to create a property boolean.

=cut

sub newBoolean {
  require WebService::Cmis::Property::Boolean;
  return new WebService::Cmis::Property::Boolean(@_);
}

=item newDateTime(%params) -> $propertyDateTime

static helper utility to create a property string.

=cut

sub newDateTime {
  require WebService::Cmis::Property::DateTime;
  return new WebService::Cmis::Property::DateTime(@_);
}

=item newDecimal(%params) -> $propertyDecimal

static helper utility to create a property string.

=cut

sub newDecimal {
  require WebService::Cmis::Property::Decimal;
  return new WebService::Cmis::Property::Decimal(@_);
}

=item newId(%params) -> $propertyId

static helper utility to create a property string.

=cut

sub newId {
  require WebService::Cmis::Property::Id;
  return new WebService::Cmis::Property::Id(@_);
}

=item newInteger(%params) -> $propertyInteger

static helper utility to create a property string.

=cut

sub newInteger {
  require WebService::Cmis::Property::Integer;
  return new WebService::Cmis::Property::Integer(@_);
}

=item newString(%params) -> $propertyString

static helper utility to create a property string.

=cut

sub newString {
  require WebService::Cmis::Property::String;
  return new WebService::Cmis::Property::String(@_);
}

=item parseDateTime($string) -> $epochSeconds

helper utility to parse an iso date into epoch seconds

=cut

sub parseDateTime {
  require WebService::Cmis::Property::DateTime;
  return WebService::Cmis::Property::DateTime->parse(@_);
}

=item formatDateTime($epochSeconds) -> $isoDate

helper utility to format epoch seconds to iso date 

=cut

sub formatDateTime {
  require WebService::Cmis::Property::DateTime;
  return WebService::Cmis::Property::DateTime->unparse(@_);
}

=item parseBoolean($string) -> $boolean

helper utility to parse a boolean

=cut

sub parseBoolean {
  require WebService::Cmis::Property::Boolean;
  return WebService::Cmis::Property::Boolean->parse(@_);
}

=item formatBoolean($boolean) -> $string

helper utility to format a boolean

=cut

sub formatBoolean {
  require WebService::Cmis::Property::Boolean;
  return WebService::Cmis::Property::Boolean->unparse(@_);
}

=item parseId($string) -> $boolean

helper utility to parse a cmis:id

=cut

sub parseId {
  require WebService::Cmis::Property::Id;
  return WebService::Cmis::Property::Id->parse(@_);
}

=item formatId($id) -> $string

helper utility to format an id

=cut

sub formatId {
  require WebService::Cmis::Property::Id;
  return WebService::Cmis::Property::Id->unparse(@_);
}

=item parseInteger($string) -> $integer

helper utility to parse an integer

=cut

sub parseInteger {
  require WebService::Cmis::Property::Integer;
  return WebService::Cmis::Property::Integer->parse(@_);
}

=item formatInteger($int) -> $string

helper utility to format an integer

=cut

sub formatInteger {
  require WebService::Cmis::Property::Integer;
  return WebService::Cmis::Property::Integer->unparse(@_);
}

=item parseDecimal($string) -> $decimal

helper utility to parse a decimal

=cut

sub parseDecimal {
  require WebService::Cmis::Property::Decimal;
  return WebService::Cmis::Property::Decimal->parse(@_);
}

=item formatDecimal($decimal) -> $string

helper utility to format a decimal

=cut

sub formatDecimal {
  require WebService::Cmis::Property::Decimal;
  return WebService::Cmis::Property::Decimal->unparse(@_);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
