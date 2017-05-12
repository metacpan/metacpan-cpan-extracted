package WebService::Cmis::ObjectType;

=head1 NAME

WebService::Cmis::ObjecType . Representation of a cmis object type

=head1 DESCRIPTION

Parent class: L<WebService::Cmis::AtomEntry>

=cut

use strict;
use warnings;
use WebService::Cmis qw(:namespaces);
use WebService::Cmis::Property ();
use WebService::Cmis::AtomEntry ();
use Error qw(:try);

our @ISA = qw(WebService::Cmis::AtomEntry);

our $CMIS_XPATH_ATTRIBUTES = new XML::LibXML::XPathExpression('./*[local-name() = "type" and namespace-uri()="'.CMISRA_NS.'"]/*[not(starts-with(local-name(),"property")) and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_PROPERTY_DEFINITIONS = new XML::LibXML::XPathExpression('./*[local-name() = "type" and namespace-uri()="'.CMISRA_NS.'"]/*[starts-with(local-name(),"property") and namespace-uri() = "'.CMIS_NS.'"]');

=head1 METHODS

=over 4

=item new()

=cut

sub new {
  my $class = shift;
  my %params = @_;

  my $xmlDoc = delete $params{xmlDoc};
  my $repository = delete $params{repository};

  my $this = bless({ 
    xmlDoc => $xmlDoc,
    repository => $repository,
    attributes => \%params,
    _hasLoadedAttributes => 0,
  }, $class); 
  
  return $this;
}

sub DESTROY {
  my $this = shift;

  #print STDERR "called ObjectType::DESTROY\n";
  undef $this->{repository};
  undef $this->{xmlDoc};
  undef $this->{propertyDefs};
  undef $this->{attributes};
}

=item getAttributes -> %attrs

returns a hash of attributes of this object type

=cut

sub getAttributes {
  my $this = shift;

  unless ($this->{_hasLoadedAttributes}) {
    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_ATTRIBUTES)) {
      my $key = $node->nodeName;
      $key =~ s/^cmis://g;
      $this->{attributes}{$key} = $node->string_value
    }
    $this->{_hasLoadedAttributes} = 1;
  }

  return $this->{attributes};
}


=item getPropertyDefinitions -> %propertyDefinitions

returns a hash of L<WebService::Cmis::PropertyDefinition> objects representing each property
defined for this type.

=cut

sub getPropertyDefinitions {
  my $this = shift;

  require WebService::Cmis::PropertyDefinition;

  unless (defined $this->{propertyDefs}) {
    # when we come from the types collection the entries might not contain the property definitions.
    # reloading the self link gets the full definition
    $this->reload unless $this->_xmlDoc->exists($CMIS_XPATH_PROPERTY_DEFINITIONS);

    foreach my $propNode ($this->_xmlDoc->findnodes($CMIS_XPATH_PROPERTY_DEFINITIONS)) {
      my $propDef = new WebService::Cmis::PropertyDefinition(xmlDoc=>$propNode);
      $this->{propertyDefs}{$propDef->getId} = $propDef;
    }
  }

  return $this->{propertyDefs};
}

=item getAttribute($name) -> $value

getter to retrieve the attribute values

=cut

sub getAttribute {
  return $_[0]->getAttributes->{$_[1]};
}

=item reload

This method will re-fetch the ObjecType XML data from the CMIS
service.

=cut

sub reload {
  my $this = shift;

  throw Error::Simple("can't reload ObjectType without attributes") unless defined $this->{attributes};
  throw Error::Simple("can't reload ObjectType without an id") unless defined $this->{attributes}{id};

  my $byTypeIdUrl = $this->{repository}->getUriTemplate('typebyid');
  $byTypeIdUrl =~ s/{id}/$this->{attributes}{id}/g;

  #print STDERR "byTypeIdUrl=$byTypeIdUrl\n";

  my $result = $this->{repository}{client}->get($byTypeIdUrl, @_);

  $this->{xmlDoc} = $result->documentElement;
  undef $this->{propertyDefs};
}

=item getId() -> $id

returns the type ID of this object

=cut

sub getId {
  return $_[0]->getAttribute("id");
}


=item getBaseId 

getter for cmis:baseId

=cut 

sub getBaseId { 
  return $_[0]->getAttribute("baseId");
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

=item getQueryName 

getter for cmis:queryName

=cut 

sub getQueryName { 
  return $_[0]->getAttribute("queryName");
}

=item getContentStreamAllowed 

getter for cmis:contentStreamAllowed

=cut 

sub getContentStreamAllowed { 
  return $_[0]->getAttribute("contentStreamAllowed");
}

=item isCreatable -> $boolean

getter for cmis:creatable

=cut

sub isCreatable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('creatable'));
}

=item isFileable -> $boolean

getter for cmis:fileable

See CMIS specification document 2.1.5.1 File-able Objects

=cut

sub isFileable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('filable'));
}

=item isQueryable -> $boolean

getter for cmis:queryable

=cut

sub isQueryable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('queryable'));
}

=item isFulltextIndexed -> $boolean

getter for cmis:fulltextIndexed

=cut

sub isFulltextIndexed {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('fulltextIndexed'));
}

=item isIncludedInSupertypeQuery -> $boolean

getter for cmis:includedInSupertypeQuery

=cut

sub isIncludedInSupertypeQuery {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('includedInSupertypeQuery'));
}

=item isControllablePolicy -> $boolean

getter for cmis:controllablePolicy

=cut

sub isControllablePolicy {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('controllablePolicy'));
}

=item isControllableACL -> $boolean

getter for cmis:controllableACL

=cut

sub isControllableACL {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('controllableACL'));
}


=item isVersionable -> $boolean

getter for cmis:versionable

=cut

sub isVersionable {
  require WebService::Cmis::Property;
  return WebService::Cmis::Property::parseBoolean($_[0]->getAttribute('versionable'));
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
