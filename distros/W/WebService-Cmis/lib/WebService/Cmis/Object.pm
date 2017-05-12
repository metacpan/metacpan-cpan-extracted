package WebService::Cmis::Object;

=head1 NAME

WebService::Cmis::Object - Representation of a cmis object

=head1 DESCRIPTION

This class provides the bulk of methods to work with CMIS objects.
When creating a new object on the base of an xml document, will
it be subclassed correctly reading the C<cmis:baseTypeId> property.

  my $obj = WebService::Cmis::Object(
    repository=>$this->{repository}, 
    xmlDoc=>$xmlDoc
  );

  if ($obj->isa('WebService::Cmis::Folder')) {
    # this is a folder
  }

Parent class: L<WebService::Cmis::AtomEntry>

Sub classes: L<WebService::Cmis::Folder>, L<WebService::Cmis::Document>,
L<WebService::Cmis::Relationship>, L<WebService::Cmis::Policy>.

=cut

use strict;
use warnings;
use WebService::Cmis qw(:namespaces :relations :contenttypes :collections :utils);
use XML::LibXML qw(:libxml);
use WebService::Cmis::NotImplementedException;
use Error qw(:try);
use URI ();
use WebService::Cmis::AtomEntry ();

our @ISA = qw(WebService::Cmis::AtomEntry);

our %classOfBaseTypeId = (
  'cmis:folder' => 'WebService::Cmis::Folder',
  'cmis:document' => 'WebService::Cmis::Document',
  'cmis:relationship' => 'WebService::Cmis::Relationship',
  'cmis:policy' => 'WebService::Cmis::Policy',
);

our $CMIS_XPATH_PROPERTIES = new XML::LibXML::XPathExpression('./*[local-name()="object" and namespace-uri()="'.CMISRA_NS.'"]/*[local-name()="properties" and namespace-uri()="'.CMIS_NS.'"]//*[@propertyDefinitionId]');
our $CMIS_XPATH_ALLOWABLEACTIONS = new XML::LibXML::XPathExpression('//cmis:allowableActions');
our $CMIS_XPATH_ACL = new XML::LibXML::XPathExpression('//cmis:acl');

=head1 METHODS

=over 4

=item new(repository=>$repository, xmlDoc=>$xmlDoc) -> $object

constructor to get a specialized object, a subclass of WebService::Cmis::Object
representing a cmis:document, cmis:folder, cmis:relationship or cmis:policy.

=cut

sub new {
  my $class = shift;

  my $obj = $class->SUPER::new(@_);

  my $baseTypeId = $obj->getProperty("cmis:baseTypeId");
  return $obj unless $baseTypeId;

  my $subClass = $classOfBaseTypeId{$baseTypeId};
  return $obj unless $subClass;

  eval "use $subClass";
  if ($@) {
    throw Error::Simple($@);
  }

  return bless($obj, $subClass);
}

# resets the internal cache of this entry.
sub _initData {
  my $this = shift;

  $this->SUPER::_initData;

  $this->{properties} = undef;
  $this->{allowableActions} = undef;
  $this->{acl} = undef;
}

=item DESTROY 

clean up internal caches

=cut

sub DESTROY {
  my $this = shift;

  #print STDERR "called Object::DESTROY\n";

  $this->_initData;

  $this->{xmldoc} = undef;
  $this->{repository} = undef;
}

=item reload(%params) 

Fetches the latest representation of this object from the CMIS service.
Some methods, like document->checkout do this for you.

If you call reload with a properties filter, the filter will be in
effect on subsequent calls until the filter argument is changed. To
reset to the full list of properties, call reload with filter set to
'*'.

Parameters:

=over 4

=item * returnVersion 

=item * filter

=item * includeAllowableActions

=item * includePolicyIds

=item * includeRelationships

=item * includeACL

=item * renditionFilter

=back

=cut

sub reload {
  my ($this, %params) = @_;

  throw Error::Simple("can't reload Object without an id or xmlDoc") unless defined $this->{id} || defined $this->{xmlDoc};

  #print STDERR "reload this:\n".join("\n", map("   ".$_."=".($this->{$_}||'undef'), keys %$this))."");

  my $byObjectIdUrl = $this->{repository}->getUriTemplate('objectbyid');

  require WebService::Cmis::Property::Boolean;

  my $id = $params{id} || $this->{id} || $this->getId();

  $byObjectIdUrl =~ s/{id}/_urlEncode($id)/ge;
  $byObjectIdUrl =~ s/{filter}/_urlEncode($params{filter}||'')/ge;
  $byObjectIdUrl =~ s/{includeAllowableActions}/WebService::Cmis::Property::Boolean->unparse($params{includeAllowableActions}||'false')/ge;
  $byObjectIdUrl =~ s/{includePolicyIds}/WebService::Cmis::Property::Boolean->unparse($params{includePolicyIds}||'false')/ge;
  $byObjectIdUrl =~ s/{includeRelationships}/WebService::Cmis::Property::Boolean->unparse($params{includeRelationships}||'')/ge;
  $byObjectIdUrl =~ s/{includeACL}/WebService::Cmis::Property::Boolean->unparse($params{includeACL}||'false')/ge;
  $byObjectIdUrl =~ s/{renditionFilter}/_urlEncode($params{renditionFilter}||'')/ge;

  # SMELL: returnVersion not covered by uri template
  my %extraParams = %{$this->{extra_params}||{}};
  $extraParams{returnVersion} = $params{returnVersion} if defined $params{returnVersion};

  # auto clear cache
  #$this->{repository}{client}->removeFromCache($byObjectIdUrl, %extraParams);
  
  $this->{xmlDoc} = $this->{repository}{client}->get($byObjectIdUrl, %extraParams);
  $this->{id} = undef; # consume {id} only valid during object creation
  $this->_initData;
}

=item getId() -> $id

returns the object ID for this object.

=cut

sub getId {
  return $_[0]->getProperty("cmis:objectId");
}

=item getName() -> $name

returns the cmis:name property.

=cut

sub getName {
  return $_[0]->getProperty("cmis:name");
}


=item getPath() -> $path

returns the cmis:path property.

=cut

sub getPath {
  return $_[0]->getProperty("cmis:path");
}

=item getTypeId() -> $typeId

returns the cmis:objectTypeId property.

=cut

sub getTypeId {
  return $_[0]->getProperty("cmis:objectTypeId");
}

=item getProperties($filter) -> %properties;

returns a hash of the object's L<properties|WebService::Cmis::Property>. If
CMIS returns an empty element for a property, the property will be in the hash
with an undef value

See CMIS specification document 2.2.4.8 getProperties

=cut

sub getProperties {
  my ($this, $filter) = @_;

  unless (defined $this->{properties}) {
    require WebService::Cmis::Property;
    my $doc = $this->_getDocumentElement;
    foreach my $propNode ($doc->findnodes($CMIS_XPATH_PROPERTIES)) {
      my $property = WebService::Cmis::Property::load($propNode);
      my $propId = $property->getId;
      #print STDERR "property = ".$property->toString."\n";
      if (defined $this->{properties}{$propId}) {
        die "duplicate property $propId in ".$doc->toString(1);
      }
      $this->{properties}{$propId} = $property;
    }
  }

  return $this->{properties} if !defined($filter) || $filter eq '*';

  my $filterPattern;
  if (defined $filter && $filter ne '*') {
    $filterPattern = '^('.join('|', map {(($_ =~ /^.+:.+$/)? $_: 'cmis:'.$_)} split(/\s*,\s*/, $filter)).')$';
    #print STDERR "filterPattern=$filterPattern\n";
  }

  my %filteredProps = map {$_ => $this->{properties}{$_}} grep {/$filterPattern/} keys %{$this->{properties}};
  return \%filteredProps;
}

=item getProperty($propName) -> $propValue

returns the value of a given property or undef if not available.

This is not covered by the cmis specs but makes live easier.

=cut

sub getProperty {
  my ($this, $propName) = @_;

  my $props = $this->getProperties;
  return unless $props->{$propName};
  return $props->{$propName}->getValue;
}

=item getAllowableActions() -> %allowableActions

returns a hash of allowable actions, keyed off of the action name.

  my $allowableActions = $obj->getAllowableActions;
  while (my ($action, $booleanFlag) = each %$allowableActions) {
    print "$action=$booleanFlag\n";
  }

See CMIS specification document 2.2.4.6 getAllowableActions

=cut

sub getAllowableActions { 
  my $this = shift;

  unless (defined $this->{allowableActions}) {
    my $node;

    if ($this->{xmlDoc}->exists($CMIS_XPATH_ALLOWABLEACTIONS)) {
      _writeCmisDebug("getting allowable actions from doc");

      ($node) = $this->{xmlDoc}->findnodes($CMIS_XPATH_ALLOWABLEACTIONS);

    } else {
      my $url = $this->getLink(ALLOWABLEACTIONS_REL);
      my $result = $this->{repository}{client}->get($url);
      $node = $result->getDocumentElement;
    }

    #print STDERR "getAllowableActions: result=".$node->toString(2)."\n";

    require WebService::Cmis::Property::Boolean;

    foreach my $node ($node->childNodes) {
      #print STDERR "node=".$node->toString(1)."\n";
      next unless $node->nodeType == XML_ELEMENT_NODE;
      $this->{allowableActions}{$node->localname} = WebService::Cmis::Property::Boolean->parse($node->string_value);
    } 
  }

  return $this->{allowableActions};
}

=item getACL() -> $acl

returns the L<access controls|WebService::Cmis::ACL> for this object.

The repository must have ACL capabilities 'manage' or 'discover'.

The optional C<onlyBasicPermissions> argument is currently not supported.

See CMIS specification document 2.2.10.1 getACL

=cut

sub getACL {
  my $this = shift;

  unless (defined $this->{acl}) {

    unless ($this->{repository}->getCapabilities()->{'ACL'} =~ /^(manage|discover)$/) {
      throw WebService::Cmis::NotSupportedException("This repository does not allow to manage ACLs"); 
    }

    require WebService::Cmis::ACL;

    my $node;

    if ($this->{xmlDoc}->exists($CMIS_XPATH_ACL)) {
      _writeCmisDebug("getting acl from doc");
      ($node) = $this->{xmlDoc}->findnodes($CMIS_XPATH_ACL);
    } else {
      my $url = $this->getLink(ACL_REL);
      my $result = $this->{repository}{client}->get($url);
      $node = $result->getDocumentElement;
    }

    $this->{acl} = new WebService::Cmis::ACL(xmlDoc=>$node);
  }

  return $this->{acl};
}

=item getSelfLink -> $href

returns the URL used to retrieve this object.

=cut

sub getSelfLink {
  return $_[0]->getLink(SELF_REL);
}

=item getEditLink -> $href

returns the URL that can be used with the HTTP PUT method to modify the
atom:entry for the CMIS resource

See CMIS specification document 3.4.3.1 Existing Link Relations

=cut

sub getEditLink {
  return $_[0]->getLink(EDIT_MEDIA_REL);
}

=item getAppliedPolicies(%params) -> $atomFeed

returns the L<list of policies|WebService::Cmis::AtomFeed::Objects> applied to
this object.

See CMIS specification document 2.2.9.3 getAppliedPolicies

=cut

sub getAppliedPolicies { 
  my $this = shift;


  # depends on this object's canGetAppliedPolicies allowable action
  unless ($this->getAllowableActions->{'canGetAppliedPolicies'}) {
    throw WebService::Cmis::NotSupportedException('This object has canGetAppliedPolicies set to false'); 
  }

  require WebService::Cmis::AtomFeed::Objects;

  my $url = $this->getLink(POLICIES_REL, @_);
  my $result = $this->{repository}{client}->get($url, @_);

  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}

=item getObjectParents(%params) -> $atomFeedOrEntry

gets the parent(s) for the specified non-folder, fileable object.
This is either an L<atom feed of objects|WebService::Cmis::AtomFeed::Objects> or 
the parent L<cmis object|WebService::Cmis::Object> depending on the "up" relation.

The following optional arguments are - NOT YET - supported: (TODO)

=over 4

=item * filter

=item * includeRelationships

=item * renditionFilter

=item * includeAllowableActions

=item * includeRelativePathSegment

=back

See CMIS specification document 2.2.3.5 getObjectParents

=cut

sub getObjectParents {
  my $this = shift;
  my %params = @_;

  # get the appropriate 'up' link
  my $parentUrl = $this->getLink(UP_REL);

  unless ($parentUrl) {
    throw WebService::Cmis::NotSupportedException('object does not support getObjectParents');
  }
  # invoke the URL
  my $result = $this->{repository}{client}->get($parentUrl, @_);

#print STDERR "getObjectParents=".$result->toString(1)."\n";

  if ($result->documentElement->localName eq 'feed') {
    # return the result set
    require WebService::Cmis::AtomFeed::Objects;
    return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
  } else {
    # return the result set
    return new WebService::Cmis::Object(repository=>$this->{repository}, xmlDoc=>$result);
  }
}

=item getRelationships(%params) -> $atomFeed

returns a result L<set of relationship
objects|WebService::Cmis::AtomFeed::Objects> for each relationship where the
source is this object.

The following optional arguments are - NOT YET - supported: (TODO)

=over 4

=item * includeSubRelationshipTypes

=item * relationshipDirection

=item * typeId

=item * maxItems

=item * skipCount

=item * filter

=item * includeAllowableActions

=back

See CMIS specification document 2.2.8.1 getObjectRelationships

=cut

sub getRelationships {
  my $this = shift;
  my %params = @_;

  require WebService::Cmis::AtomFeed::Objects;

  my $url = $this->getLink(RELATIONSHIPS_REL);

  unless ($url) {
    throw Error::Simple('could not determine relationships URL'); 
  }

  my $result = $this->{repository}{client}->get($url, @_);
  return new WebService::Cmis::AtomFeed::Objects(repository => $this->{repository}, xmlDoc => $result);
}

=item delete(%params)

Deletes this cmis object from the repository. Note that in the case of a Folder
object, some repositories will refuse to delete it if it contains children and
some will delete it without complaint. If what you really want to do is delete
the folder and all of its descendants, use L<WebService::Cmis::Folder::deleteTree> instead.

=over 4

=item * allVersions: if TRUE (default), then delete all versions of the
document. If FALSE, delete only the document object specified. The Repository
MUST ignore the value of this parameter when this service is invoke on a
non-document object or non-versionable document object.

=back

See CMIS specification document 2.2.4.14 delete

=cut

sub delete {
  my $this = shift;
  my %params = @_;

  my $url = $this->getSelfLink;
  return $this->{repository}{client}->delete($url, @_);
}

=item move($sourceFolder, $targetFolder) -> $this

Moves the specified file-able object from one folder to another. 

See CMIS specification document 2.2.4.13 move

=cut

sub move { 
  my ($this, $sourceFolder, $targetFolder) = @_;

  return $this->moveTo($targetFolder) unless defined $sourceFolder;

  my $targetUrl = $targetFolder->getLink(DOWN_REL, ATOM_XML_FEED_TYPE_P, 1);

  my $uri = new URI($targetUrl);
  my %queryParams = ($uri->query_form, sourceFolderId=>$sourceFolder->getId);
  $uri->query_form(%queryParams);
  $targetUrl = $uri->as_string;

  # post it to to the checkedout collection URL
  my $result = $this->{repository}{client}->post($targetUrl, $this->_xmlDoc->toString, ATOM_XML_ENTRY_TYPE);

  # now that the doc is moved, we need to refresh the XML
  # to pick up the prop updates related to the move
  $this->{xmlDoc} = $result;
  $this->_initData;

  #return new WebService::Cmis::Object(repository=>$this->{repository}, xmlDoc=>$result);
  return $this;
}

=item moveTo($targetFolder) -> $this

Convenience function to move an object from its parent folder to a given target folder.
Same as Folder::addObject but in reverse logic

=cut

sub moveTo {
  my ($this, $targetFolder) = @_;

  my $parents = $this->getObjectParents;
  my $parentFolder;

  if ($parents->isa("WebService::Cmis::AtomFeed")) {
    $parentFolder = $parents->getNext; #SMELL: what if there are multiple parents
  } else {
    $parentFolder = $parents;
  }

  return $this->move($parentFolder, $targetFolder);
}

=item unfile($folder)

removes this object from the given parent folder.
If the $folder parameter is not provided, the document is removed from any of its parent folders.

See CMIS specification document 2.2.5.2

=cut

sub unfile {
  my $this = shift;
  my $folder = shift;

  unless ($this->{repository}->getCapabilities()->{'Unfiling'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support unfiling");
  }

  my $unfiledLink = $this->{repository}->getCollectionLink(UNFILED_COLL, ATOM_XML_FEED_TYPE_P);

  if ($folder) {
    my $uri = new URI($unfiledLink);
    my %queryParams = ($uri->query_form, folderId=>$folder->getId);
    $uri->query_form(%queryParams);
    $unfiledLink = $uri->as_string;
  }

  # post it to to the unfiled collection URL
  my $result = $this->{repository}{client}->post($unfiledLink, $this->_xmlDoc->toString, ATOM_XML_ENTRY_TYPE);

  # now that the doc is moved, we need to refresh the XML
  # to pick up the prop updates related to the move
  $this->reload;

  #return new WebService::Cmis::Object(repository=>$this->{repository}, xmlDoc=>$result);
  return $this;
}

=item updateProperties($propertyList) -> $this

TODO: The optional changeToken is not yet supported.

Updates the properties of an object with the properties provided.
Only provide the set of properties that need to be updated.


  $folder = $repo->getObjectByPath('/SomeFolder');
  $folder->getName; # returns SomeFolder

  $folder->updateProperties([
    WebService::Cmis::Property::newString(
      id => 'cmis:name',
      value => 'SomeOtherName',
    ),
  ]);

  $folder->getName; # returns SomeOtherName

See CMIS specification document 2.2.4.12 updateProperties

=cut

sub updateProperties {
  my $this = shift;

  # get the self link
  my $selfUrl = $this->getSelfLink;

  # build the entry based on the properties provided
  my $xmlEntryDoc = $this->{repository}->createEntryXmlDoc(properties => (@_));

  # do a PUT of the entry
  my $result = $this->{repository}{client}->put($selfUrl, $xmlEntryDoc->toString, ATOM_XML_TYPE);

  # reset the xmlDoc for this object with what we got back from
  # the PUT, then call initData we dont' want to call
  # self.reload because we've already got the parsed XML--
  # there's no need to fetch it again

  $this->{xmlDoc} = $result;
  $this->_initData;

  return $this;
}

=item getSummary -> $summary

overrides AtomEntry::getSummary

=cut

sub getSummary {
  my $this = shift;

  my $summary;

  $summary = $this->getProperty("cm:description"); # since alfresco 4
  $summary = $this->getProperty("dc:description") unless defined $summary; # dublin core
  $summary = $this->SUPER::getSummary() unless defined $summary; # good ol' atom

  return $summary;
}

=item updateSummary 

overrides AtomEntry::updateSummary 

=cut

sub updateSummary {
  my ($this, $text) = @_;

  my $vendorName = $this->{repository}->getRepositoryInfo->{vendorName};

# if ($vendorName =~ /alfresco/i) {
#   return $this->updateProperties([
#     WebService::Cmis::Property::newString(
#       id => 'cm:description',
#       value => $text,
#     ),
#   ]);
# }

  # vendors using dublin core 
  if ($vendorName =~ /nuxeo/i) {
    return $this->updateProperties([
      WebService::Cmis::Property::newString(
        id => 'dc:description',
        value => $text,
      ),
    ]);
  }

  # fallback to atom:summary. some vendors sync this into their model properly.
  return $this->SUPER::updateSummary($text);
}


=item rename($string) -> $this

rename this object updating its cmis:properties

=cut

sub rename {
  return $_[0]->updateProperties([
    WebService::Cmis::Property::newString(
      id => 'cmis:name',
      value => $_[1],
    ),
  ]);
}

=item applyACL($acl) -> $acl

applies specified L<ACL|WebService::Cmis::ACL> to the object and returns
the updated ACLs as stored on the server.

  my $obj = $repo->getObject($id);
  my $acl = $obj->getACL->addEntry(
    new WebService::Cmis::ACE(
      principalId => 'jdoe',
      permissions => ['cmis:write', 'cmis:read'],
      direct => 'true',
    )
  );
  my $updatedACL => $obj->applyACL($acl);

See CMIS specification document 2.2.10.2 applyACL

=cut

sub applyACL { 
  my ($this, $acl) = @_;

  unless ($this->{repository}->getCapabilities()->{'ACL'} eq 'manage') {
    throw WebService::Cmis::NotSupportedException("This repository does not allow to manage ACLs"); 
  }

  my $url = $this->getLink(ACL_REL);
  unless ($url) {
     throw Error::Simple("Could not determine the object's ACL URL"); 
  }

  my $xmlDoc = $acl->getXmlDoc;
  my $result = $this->{repository}{client}->put($url, $xmlDoc->toString(2), CMIS_ACL_TYPE);
  #print STDERR "result=".$result->toString(1)."\n";

  $this->{acl} =  new WebService::Cmis::ACL(xmlDoc=>$result);

  return $this->{acl};
}

=item applyPolicy()

TODO: This is not yet implemented.

=cut

sub applyPolicy { throw WebService::Cmis::NotImplementedException; }

=item createRelationship()

TODO: This is not yet implemented.

=cut

sub createRelationship { throw WebService::Cmis::NotImplementedException; }

=item removePolicy()

TODO: This is not yet implemented.

=cut

sub removePolicy { throw WebService::Cmis::NotImplementedException; }

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
