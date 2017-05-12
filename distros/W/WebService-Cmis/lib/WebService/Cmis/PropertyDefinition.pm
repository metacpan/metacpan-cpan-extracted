package WebService::Cmis::PropertyDefinition;

=head1 NAME

WebService::Cmis::PropertyDefinition

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a  property definition of an object type
type.

=cut

use strict;
use warnings;
use XML::LibXML qw(:libxml);
use Error qw(:try);

=head1 METHODS

=over 4

=item new(%params)

constructur. %params must provide an xmlDoc property.

=cut

sub new { 
  my $class = shift;

  my $this= bless({@_}, $class);

}

=item getAttributes -> %attrs

returns a hash of attributes of this property definition

=cut

sub getAttributes {
  my $this = shift;

  unless (defined $this->{attributes}) {
    throw Error::Simple("no xmlDoc while reading attributes") unless defined $this->{xmlDoc};

    $this->{attributes} = ();
    foreach my $node ($this->{xmlDoc}->childNodes) {
      next unless $node->nodeType eq XML_ELEMENT_NODE;
      my $key = $node->nodeName;
      $key =~ s/^cmis://g;
      $this->{attributes}{$key} = $node->string_value;
    }
  }

  return $this->{attributes};
}

=item getAttribute($name) -> $value

getter to retrieve the attribute values

=cut

sub getAttribute {
  return $_[0]->getAttributes->{$_[1]};
}

=item toString

returns a string representation of this cmis property

=cut

sub toString { 
  return $_[0]->getId;
}

=item getId

getter for cmis:id

=cut

sub getId {
  return $_[0]->getAttribute("id");
}


=item getCardinality

getter for cmis:cardinality

=cut

sub getCardinality {
  return $_[0]->getAttribute("cardinality");
}

=item getDescription

getter for cmis:description

=cut

sub getDescription {
  return $_[0]->getAttribute("description");
}

=item getDisplayName

getter for cmis:displayName

=cut

sub getDisplayName {
  return $_[0]->getAttribute("displayName");
}

=item getLocalName

getter for cmis:localName

=cut

sub getLocalName {
  return $_[0]->getAttribute("localName");
}

=item getLocalNamespace

getter for cmis:localNamespace

=cut

sub getLocalNamespace {
  return $_[0]->getAttribute("localNamespace");
}

=item getPropertyType

getter for cmis:propertyType

=cut

sub getPropertyType {
  return $_[0]->getAttribute("propertyType");
}

=item getQueryName

getter for cmis:queryName

=cut

sub getQueryName {
  return $_[0]->getAttribute("queryName");
}

=item getUpdatability

getter for cmis:updatability

=cut

sub getUpdatability {
  return $_[0]->getAttribute("updatability");
}

=item isInherited

getter for cmis:inherited

=cut

sub isInherited {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute("inherited"));
}

=item isOpenChoice

getter for cmis:openchoice

=cut

sub isOpenChoice {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute("openChoice"));
}

=item isOrderable

getter for cmis:orderable

=cut

sub isOrderable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute("orderable"));
}

=item isQueryable

getter for cmis:queryable

=cut

sub isQueryable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute("queryable"));
}

=item isRequired

getter for cmis:required

=cut

sub isRequired {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute("required"));
}

=back

=head1 AUTHOR

Michael Daum C<< <daum@michaeldaumconsulting.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
