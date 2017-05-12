package WebService::Cmis::Repository;

=head1 NAME

WebService::Cmis::Repository - Representation of a cmis repository

=head1 DESCRIPTION

After fetching a L<WebService::Cmis::Client> object, fetching the
repository is the next thing to do in most cases using L<WebService::Cmis::Client/getRepository>.

  my $repo = WebService::Cmis::getClient->getRepository('repositoryId');

=cut

use strict;
use warnings;

use WebService::Cmis qw(:namespaces :collections :utils :relations :contenttypes);
use XML::LibXML qw(:libxml);
use Error qw(:try);
use WebService::Cmis::NotImplementedException ();
use WebService::Cmis::NotSupportedException ();
use WebService::Cmis::ClientException ();

our $CMIS_XPATH_REPOSITORYINFO = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() != "capabilities" and local-name() != "aclCapability" and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_CAPABILITIES = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() = "capabilities" and namespace-uri() = "'.CMIS_NS.'"]/*');
our $CMIS_XPATH_SUPPORTED_PERMISSIONS = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() = "aclCapability" and namespace-uri() = "'.CMIS_NS.'"]/*[local-name() = "supportedPermissions" and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_PROPAGATION = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() = "aclCapability" and namespace-uri() = "'.CMIS_NS.'"]/*[local-name() = "propagation" and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_PERMISSION_DEFINITION = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() = "aclCapability" and namespace-uri() = "'.CMIS_NS.'"]/*[local-name() = "permissions" and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_PERMISSION_MAP = new XML::LibXML::XPathExpression('./*[local-name() = "repositoryInfo" and namespace-uri() = "'.CMISRA_NS.'"]/*[local-name() = "aclCapability" and namespace-uri() = "'.CMIS_NS.'"]/*[local-name() = "mapping" and namespace-uri() = "'.CMIS_NS.'"]');
our $CMIS_XPATH_URITEMPLATE = new XML::LibXML::XPathExpression('./*[local-name() = "uritemplate" and namespace-uri() = "'.CMISRA_NS.'"]');
our $CMIS_XPATH_COLLECTION = new XML::LibXML::XPathExpression('./*[local-name() = "collection" and namespace-uri()="'.APP_NS.'" and @href]');

=head1 METHODS

=over 4

=item new($client, $xmlDoc)

Create a new repository object using the given $client and loading
the information stored in the $xmlDoc.

=cut

sub new {
  my ($class, $client, $xmlDoc) = @_;

  my $this = bless({
    client => $client,
    xmlDoc => $xmlDoc,
  }, $class);

  $this->_initData;
  
  return $this;
}

=item getClient() -> L<WebService::Cmis::Client>

returns the the client object used to communicate with the repository.

=cut

sub getClient {
  return $_[0]->{client};
}


# internal function to reset cached data
sub _initData {
  my $this = shift;

  $this->{repositoryInfo} = undef;
  $this->{capabilities} = undef;
  $this->{uriTemplates} = undef;
  $this->{permDefs} = undef;
  $this->{permMap} = undef;
  $this->{permissions} = undef;
  $this->{propagation} = undef;
  $this->{uriTempaltes} = undef;
  $this->{collectionLink} = undef;
  $this->{typeDefs} = undef;
}

sub DESTROY {
  my $this = shift;

  #print STDERR "called Repository::DESTROY\n";
  
  undef $this->{repositoryInfo};
  undef $this->{capabilities};
  undef $this->{uriTemplates};
  undef $this->{permDefs};
  undef $this->{permMap};
  undef $this->{permissions};
  undef $this->{propagation};
  undef $this->{uriTempaltes};
  undef $this->{collectionLink};
  undef $this->{typeDefs};
  undef $this->{xmlDoc};
  undef $this->{client};
  undef $this->{fileMage};
}

=item toString()

return a string representation of this repository

=cut

sub toString {
  my $this = shift;
  return $this->getRepositoryId;
}

=item reload()

This method will re-fetch the repository's XML data from the CMIS
repository.

=cut

sub reload {
  my $this = shift;

  $this->{xmlDoc} = $this->{client}->get;
  $this->_initData;
}

#internal helper to make sure the xmlDoc is loaded
sub _xmlDoc {
  $_[0]->reload unless defined $_[0]->{xmlDoc};
  return $_[0]->{xmlDoc};
}

=item getRepositoryId()

returns this repository's ID

=cut

sub getRepositoryId {
  return $_[0]->getRepositoryInfo->{repositoryId};
}

=item getRepositoryName()

returns this repository's name

=cut

sub getRepositoryName {
  return $_[0]->getRepositoryInfo->{repositoryName};
}

=item getRepositoryInfo() -> %info

returns this repository's info record

See CMIS specification document 2.2.2.2 getRepositoryInfo

=cut

sub getRepositoryInfo {
  my $this = shift;

  unless (defined $this->{repositoryInfo}) {
    $this->{repositoryInfo}{$_->localname} = $_->string_value
      foreach $this->_xmlDoc->findnodes($CMIS_XPATH_REPOSITORYINFO);
  }

  return $this->{repositoryInfo};
}

=item getCapabilities() -> %caps

returns this repository's capabilities

=cut

sub getCapabilities {
  my $this = shift;

  unless (defined $this->{capabilities}) {
    require WebService::Cmis::Property::Boolean;

    $this->{capabilities} = {};
    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_CAPABILITIES)) {
       my $key = $node->localname;
       $key =~ s/^capability//;

       my $val = $node->string_value;
       $val = WebService::Cmis::Property::Boolean->parse($val) if $val =~ /^(true|false)$/;
       $this->{capabilities}{$key} = $val;
    }
  }

  return $this->{capabilities};
}

=item getSupportedPermissions() -> $permissions

returns this repository's supported permissions.
values are:

  basic: indicates that the CMIS Basic permissions are supported
  repository: indicates that repository specific permissions are supported
  both: indicates that both CMIS basic permissions and repository specific permissions are supported

=cut

sub getSupportedPermissions {
  my $this = shift;

  unless ($this->getCapabilities()->{'ACL'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support ACLs"); 
  }

  unless (defined $this->{permissions}) {
    $this->{permissions} = $this->_xmlDoc->findvalue($CMIS_XPATH_SUPPORTED_PERMISSIONS);
  }

  return $this->{permissions};
}

=item getPropagation() -> $string

returns the value of the cmis:propagation element. Valid values are:

  objectonly: indicates that the repository is able to apply ACEs
    without changing the ACLs of other objects

  propagate: indicates that the repository is able to apply ACEs to a
    given object and propagate this change to all inheriting objects

=cut

sub getPropagation {
  my $this = shift;

  unless ($this->getCapabilities()->{'ACL'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support ACLs"); 
  }

  unless (defined $this->{propagation}) {
    $this->{propagation} = $this->_xmlDoc->findvalue($CMIS_XPATH_PROPAGATION);
  }

  return $this->{propagation};
}

=item getPermissionDefinitions() -> %permDefs

Returns a hash of permission definitions for this repository. The key is the
permission string or technical name of the permission and the value is the
permission description.

=cut

sub getPermissionDefinitions {
  my $this = shift;

  unless ($this->getCapabilities()->{'ACL'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support ACLs"); 
  }

  unless (defined $this->{permDefs}) {
    
    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_PERMISSION_DEFINITION)) {
      my ($permNode) = $node->getElementsByTagNameNS(CMIS_NS, 'permission'); # these two getElementsByTagNameNS are ok
      my ($descNode) = $node->getElementsByTagNameNS(CMIS_NS, 'description');
 
      if (defined $permNode && defined $descNode) {
        # alfresco has got a detailed sub node
        $this->{permDefs}{$permNode->string_value} = $descNode->string_value;
      } else {
        # TODO: nuxeo looks differernt down here
      }
    }
  }

  return $this->{permDefs};
}

=item getPermissionMap() -> %permMap

returns a hash representing the permission mapping table where
each key is a permission key string and each value is a list of one or
more permissions the principal must have to perform the operation.

=cut

sub getPermissionMap {
  my $this = shift;

  unless ($this->getCapabilities()->{'ACL'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support ACLs"); 
  }

  unless (defined $this->{permMap}) {
  
    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_PERMISSION_MAP)) {
      my @permList = ();
      my ($keyNode) = $node->getElementsByTagNameNS(CMIS_NS, 'key'); # these two getElementsByTagNameNS are ok
      foreach my $permNode ($node->getElementsByTagNameNS(CMIS_NS, 'permission')) {
        push @permList, $permNode->string_value;
      }
      $this->{permMap}{$keyNode->string_value} = \@permList;
    }
  }

  return $this->{permMap}
}

=item getUriTemplates() -> %templates

returns a hash of URI templates the repository service knows about.

=cut

sub getUriTemplates {
  my $this = shift;

  unless (defined $this->{uriTemplates}) {

    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_URITEMPLATE)) {
      my $template;
      my $type;
      my $mediaType;

      foreach my $subNode ($node->childNodes) {
        next if $subNode->nodeType != XML_ELEMENT_NODE;
        my $localName = $subNode->localname;
        if ($localName eq 'template') {
          $template = $subNode->string_value;
        } elsif ($localName eq 'type') {
          $type = $subNode->string_value;
        } elsif ($localName eq 'mediatype') {
          $mediaType = $subNode->string_value;
        }
        last if defined $template && defined $type && defined $mediaType;
      }
      $this->{uriTemplates}{$type} = {
        template => $template,
        type => $type,
        mediatype => $mediaType,
      };
    }
  }

  return $this->{uriTemplates};
}

=item getUriTemplate($type) -> $template 

returns an uri template for the given type

=cut

sub getUriTemplate {
  my ($this, $type) = @_;

  return $this->getUriTemplates()->{$type}->{template};
}

=item getRootFolder() -> $folder

returns the root folder of the repository

=cut

sub getRootFolder {
  my $this = shift;

  my $id = $this->getRepositoryInfo->{'rootFolderId'};

  return $this->getFolder($id) if $id;

  # some repos don't advertise the root folder
  return $this->getObjectByPath("/");
}

=item getFolder($id) -> $foldeer

returns the a folder object of the given id

=cut

sub getFolder {
  my ($this, $id) = @_;

  require WebService::Cmis::Folder;
  return new WebService::Cmis::Folder(repository=>$this, id=>$id);
}

=item getCollection($collectionType, %args) -> $atomFeed

returns a AtomFeed of objects returned for the specified collection.

If the query collection is requested, an exception will be throwd.
That collection isn't meant to be retrieved.

=cut

sub getCollection { 
  my $this = shift;
  my $collectionType = shift;

  if ($collectionType eq QUERY_COLL) {
    throw Error::Simple("query collection not supported"); # SMELL: use a custom exception
  }

  my $link = $this->getCollectionLink($collectionType);
  my $result = $this->{client}->get($link, @_);
  #_writeCmisDebug("result=".$result->toString);

  # return the result set
  if ($collectionType eq TYPES_COLL) {
    require WebService::Cmis::AtomFeed::ObjectTypes;
    return new WebService::Cmis::AtomFeed::ObjectTypes(repository=>$this, xmlDoc=>$result);
  } else {
    require WebService::Cmis::AtomFeed::Objects;
    return new WebService::Cmis::AtomFeed::Objects(repository=>$this, xmlDoc=>$result);
  }
}

=item getTypeDefinition($typeId) -> $objectType

returns an ObjectType object for the specified object type id.

See CMIS specification document 2.2.2.5 getTypeDefinition

folderType = repo.getTypeDefinition('cmis:folder')

=cut

sub getTypeDefinition { 
  my ($this, $id) = @_;

  require WebService::Cmis::ObjectType;
  my $objectType = new WebService::Cmis::ObjectType(repository=>$this, id=>$id);
  $objectType->reload;
  return $objectType;
}

=item getCollectionLink($collectionType) -> $href

returns the link HREF from the specified collectionType
(CHECKED_OUT_COLL, for example).

=cut

sub getCollectionLink { 
  my ($this, $collectionType) = @_;

  unless ($this->{collectionLink}) {
  
    foreach my $node ($this->_xmlDoc->findnodes($CMIS_XPATH_COLLECTION)) {
      my $href = $node->attributes->getNamedItem('href')->value;
      foreach my $subNode ($node->childNodes) {
        next unless $subNode->nodeType == XML_ELEMENT_NODE && $subNode->localname eq 'collectionType';
        $this->{collectionLink}{$subNode->string_value} = $href;
      }
    }
    #_writeCmisDebug("collection link for $collectionType: $this->{collectionLink}{$collectionType}");
  }

  return $this->{collectionLink}{$collectionType};
}

=item getLink($relation) -> $href

returns the HREF attribute of an Atom link element for the
specified rel.

=cut

sub getLink { 
  my ($this, $relation) = @_;

  my $href = $this->_xmlDoc->find('./*[local-name() = "link" and namespace-uri() = "'.ATOM_NS.'" and @rel="'.$relation.'"]/@href');
  return "".$href if $href;
  return;
}

=item getObjectByPath($path, %params) -> $cmisObj

returns an object given the path to the object.

  my $doc = $repo->getObjectByPath("/User homes/jeff/sample.pdf");
  my $title = $doc->getTitle();

These optional arguments are supported:

=over 4

=item filter: See section 2.2.1.2.1 Properties.

=item includeAllowableActions: See section 2.2.1.2.6 Allowable Actions. 

=item includeRelationships: See section 2.2.1.2.2 Relationships.

=item renditionFilter: See section 2.2.1.2.4 Renditions.

=item includePolicyIds: See section 2.2.1.2.2 Relationships.

=item includeACL: See section 2.2.1.2.5 ACLs.

=back

See CMIS specification document 2.2.4.9 getObjectByPath

=cut

sub getObjectByPath {
  my $this = shift;
  my $path = shift;
  my %params = @_;

  # get the uritemplate
  my $template = $this->getUriTemplate('objectbypath');

  require WebService::Cmis::Property::Boolean;

  $path ||= '/';
  $template =~ s/{path}/delete $params{path}||$path/ge;
  $template =~ s/{filter}/delete $params{filter}||''/ge;
  $template =~ s/{includeAllowableActions}/WebService::Cmis::Property::Boolean->unparse(delete $params{includeAllowableActions}||'false')/ge;
  $template =~ s/{includePolicyIds}/WebService::Cmis::Property::Boolean->unparse(delete $params{includePolicyIds}||'false')/ge;
  $template =~ s/{includeRelationships}/WebService::Cmis::Property::Boolean->unparse(delete $params{includeRelationships}||'')/ge;
  $template =~ s/{includeACL}/WebService::Cmis::Property::Boolean->unparse(delete $params{includeACL}||'false')/ge;
  $template =~ s/{renditionFilter}/delete $params{renditionFilter}||''/ge;

  #print STDERR "template=$template\n";

  # do a GET against the URL
  my $result;
  
  try {
    $result = $this->{client}->get($template, @_);
  } catch WebService::Cmis::ClientException with {
    # ignore
  };

  return unless $result;

  require WebService::Cmis::Object;
  return new WebService::Cmis::Object(repository=>$this, xmlDoc=>$result, extra_params=>\%params);
}

=item getObject($id, %params) -> $cmisObj

returns an object given the specified object ID.

See CMIS specification document 2.2.4.7 getObject

=cut

sub getObject {
  my $this = shift;
  my $id = shift;
  my %params = @_;

  require WebService::Cmis::Object;

  my $obj;
  try {
    $obj = new WebService::Cmis::Object(repository=>$this, id=>$id, extra_params=>\%params);
  } catch WebService::Cmis::ClientException with {
    # ignore
  };

  return $obj;
}

=item getCheckedOutDocs(%params) -> $atomFeed

returns a result set of cmis objects that
are currently checked out.

See CMIS specification document 2.2.3.6 getCheckedOutDocs

These optional arguments are supported:

=over 4

=item folderId

=item maxItems

=item skipCount

=item orderBy

=item filter

=item includeRelationships

=item renditionFilter

=item includeAllowableActions

=back

=cut

sub getCheckedOutDocs {
  my $this = shift;
  return $this->getCollection(CHECKED_OUT_COLL, @_)
}

=item getUnfiledDocs(%params):

returns a AtomFeed of cmis objects that
are currently unfiled.

These optional arguments are supported:

=over 4

=item folderId

=item maxItems

=item skipCount

=item orderBy

=item filter

=item includeRelationships

=item renditionFilter

=item includeAllowableActions

=back

=cut

sub getUnfiledDocs {
  my $this = shift;

  unless ($this->getCapabilities->{'Unfiling'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support unfiling");
  }

  return $this->getCollection(UNFILED_COLL, @_);
}

=item getTypeDefinitions(%params) -> $atomFeed

returns a AtomFeed of ObjectTypes holding
the base types in the repository.

Use the normal paging options.

=cut

sub getTypeDefinitions {
  my $this = shift;
  return $this->getCollection(TYPES_COLL, @_);
}

=item createEntryXmlDoc(
  summary=>$summary
  folder=>$parentFolder,
  properties=>$propsList, 
  contentFile=>$filename, 
  contentData=>$data, 
  contentType=>$type
) -> $atomEntry

helper method that knows how to build an Atom entry based
on the properties and, optionally, the contentFile provided.

=cut

sub createEntryXmlDoc {
  my $this = shift;
  my %params = @_;

  my $xmlDoc = new XML::LibXML::Document('1.0', 'UTF-8');
  my $entryElement = $xmlDoc->createElementNS(ATOM_NS, "entry");
  $xmlDoc->setDocumentElement($entryElement);

  $entryElement->setNamespace(APP_NS, "app", 0);
  $entryElement->setNamespace(CMISRA_NS, "cmisra", 0);
  $entryElement->setNamespace(CMIS_NS, "cmis", 0);
        
  $entryElement->appendTextChild("summary", $params{summary}) if defined $params{summary};

  # if there is a File, encode it and add it to the XML
  my $contentFile = $params{contentFile};
  my $contentData = $params{contentData};
  if (defined $contentFile || defined $contentData) {

    my $mimeType = $params{contentType};
    
    # read file
    unless (defined $contentData) {
      my $fh;

      open($fh, '<', $contentFile) 
        or throw Error::Simple("can't open file $contentFile"); # SMELL: use a custom exception

      local $/ = undef;# set to read to EOF
      $contentData = <$fh>;
      close($fh);
      $contentData = '' unless $contentData; # no undefined
    }

    # need to determine the mime type
    unless (defined $mimeType) {

      # get the file mage used for checking
      unless (defined $this->{fileMage}) {
        require File::MMagic;
        $this->{fileMage} = new File::MMagic;
      }

      $mimeType = $this->{fileMage}->checktype_contents($contentData);

      # mimeType fallback
      $mimeType = 'application/binary' unless defined $mimeType;
    }

    # This used to be ATOM_NS content but there is some debate among
    # vendors whether the ATOM_NS content must always be base64
    # encoded. The spec does mandate that CMISRA_NS content be encoded
    # and that element takes precedence over ATOM_NS content if it is
    # present, so it seems reasonable to use CMIS_RA content for now
    # and encode everything. (comments from cmislib)

    require MIME::Base64;
    $contentData = MIME::Base64::encode_base64($contentData);

    my $contentElement = $xmlDoc->createElement('cmisra:content');
    $contentElement->appendTextChild("cmisra:mediatype", $mimeType);
    $contentElement->appendTextChild("cmisra:base64", $contentData);
    $entryElement->appendChild($contentElement);
  }

  my $objectElement = $entryElement->appendChild($xmlDoc->createElement('cmisra:object'));

  if (defined $params{properties}) {
    my $propsElement = $objectElement->appendChild($xmlDoc->createElement('cmis:properties'));
    
    foreach my $property (@{$params{properties}}) {
      #_writeCmisDebug("property=".$property->toString);

      # a name is required for most things, but not for a checkout
      if ($property->getId eq 'cmis:name') {
        _writeCmisDebug("got cmis:name property");
        $entryElement->appendTextChild("title", $property->getValue);
      }

      # create property element and add to container
      $propsElement->appendChild($property->toXml($xmlDoc));
    }
  }

  # add folderId
  $objectElement->appendTextChild('cmis:folderId', $params{folder}->getId) if defined $params{folder};

  # add repositoryId
  $objectElement->appendTextChild('cmis:repositoryId', $this->getRepositoryId);

  #print STDERR "### created new entry:\n".$xmlDoc->toString(1)."\n###\n";
  return $xmlDoc;
}

=item createObject($parentFolder, properties => $propertyList, %params);

creates a new CMIS Objec in the given folder using 
the properties provided.

To specify a custom object type, pass in a Property for
cmis:objectTypeId representing the type ID
of the instance you want to create. If you do not pass in an object
type ID, an instance of 'cmis:document' will be created.

=cut

sub createObject {
  my $this = shift;
  my $parentFolder = shift;

  my $postUrl;
  if (defined $parentFolder) {
    # get the folder represented by folderId.
    # we'll use his 'children' link post the new child
    $postUrl = $parentFolder->getChildrenLink;
        
  } else {
    unless ($this->getCapabilities->{'Unfiling'}) {
      throw WebService::Cmis::NotSupportedException("This repository does not support unfiling");
    }

    # post to unfiled collection
    $postUrl = $this->getCollectionLink(UNFILED_COLL);
  }

  # build the Atom entry
  my $xmlDoc = $this->createEntryXmlDoc(folder=>$parentFolder, @_);

  # post the Atom entry
  my $result = $this->{client}->post($postUrl, $xmlDoc->toString, ATOM_XML_ENTRY_TYPE);

  # what comes back is the XML for the new document,
  # so use it to instantiate a new document
  # then return it
  require WebService::Cmis::Object;
  return new WebService::Cmis::Object(repository=>$this, xmlDoc=>$result);
}

=item getTypeChildren($typeId, %params) -> $atomFeed

returns a result set ObjectType objects corresponding to the
child types of the type specified by the typeId.

If no typeId is provided, the result will be the same as calling
getTypeDefinitions

See CMIS specification document 2.2.2.3 getTypeChildren

These optional arguments are current supported:

=over 4

=item includePropertyDefinitions

=item maxItems

=item skipCount

=back

=cut

sub getTypeChildren {
  my $this = shift;
  my $typeId = shift;

  if (defined $typeId) {
    # if a typeId is specified, get it from the type definition's "down" link
    my $targetType = $this->getTypeDefinition($typeId);
    my $childrenUrl = $targetType->getLink(DOWN_REL, ATOM_XML_FEED_TYPE_P);

    #print STDERR "childrenUrl=$childrenUrl\n";

    my $result = $this->{client}->get($childrenUrl, @_);

    require WebService::Cmis::AtomFeed::ObjectTypes;
    return new WebService::Cmis::AtomFeed::ObjectTypes(repository=>$this, xmlDoc=>$result);

  } else {

    # otherwise, if a typeId is not specified, return
    # the list of base types
    return $this->getTypeDefinitions;
  }
}

=item getTypeDescendants($typeId, %params) -> $atomFeed

Returns a result set ObjectType objects corresponding to the
descendant types of the type specified by the typeId.

If no typeId is provided, the repository's "typesdescendants" URL
will be called to determine the list of descendant types.

See CMIS specification document 2.2.2.4 getTypeDescendants

These optional arguments are supported:

=over 4

=item depth

=item includePropertyDefinitions

=back

=cut

sub getTypeDescendants {
  my $this = shift;
  my $typeId = shift;
  
  my $descendUrl;
  if (defined $typeId) {
    # if a typeId is specified, get it from the type definition's, "down" link
    my $targetType = $this->getTypeDefinition($typeId);
    $descendUrl = $targetType->getLink(DOWN_REL, CMIS_TREE_TYPE_P);
  } else {
    $descendUrl = $this->getLink(TYPE_DESCENDANTS_REL);
  }

  #print STDERR "descendUrl=$descendUrl\n";

  unless (defined $descendUrl) {
    throw Error::Simple("Could not determine the type descendants URL"); # SMELL: do a custom exception
  }

  my $result = $this->{client}->get($descendUrl, @_);

  require WebService::Cmis::AtomFeed::ObjectTypes;
  return new WebService::Cmis::AtomFeed::ObjectTypes(repository=>$this, xmlDoc=>$result);
}

=item query(statement, %params):

Returns a result set of CMIS Objects based on the CMIS
Query Language passed in as the statement. The actual objects
returned will be instances of the appropriate child class based
on the object's base type ID.

In order for the results to be properly instantiated as objects,
make sure you include 'cmis:objectId' as one of the fields in
your select statement, or just use "SELECT \*".

If you want the search results to automatically be instantiated with
the appropriate sub-class of CMIS Object you must either
include cmis:baseTypeId as one of the fields in your select statement
or just use "SELECT \*".

See CMIS specification document 2.2.6.1 query

The following optional arguments are supported:

=over 4

=item searchAllVersions

=item includeRelationships

=item renditionFilter

=item includeAllowableActions

=item maxItems

=item skipCount

=back

=cut

sub query {
  my $this = shift;
  my $statement = shift;

  # get the URL this repository uses to accept query POSTs
  my $queryUrl = $this->getCollectionLink(QUERY_COLL);

  # build the CMIS query XML that we're going to POST
  my $xmlDoc = $this->_getQueryXmlDoc($statement, @_);

  # do the POST
  my $result = $this->{client}->post($queryUrl, $xmlDoc->toString, CMIS_QUERY_TYPE);

  # return the result set
  require WebService::Cmis::AtomFeed::Objects;
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this, xmlDoc=>$result);
}

# Utility method that knows how to build CMIS query xml around the specified query statement.
sub _getQueryXmlDoc {
  my $this = shift;
  my $statement = shift;
  my %params = @_;

  my $xmlDoc = new XML::LibXML::Document('1.0', 'UTF-8');

  my $queryElement = $xmlDoc->createElementNS(CMIS_NS, "query");

  $xmlDoc->setDocumentElement($queryElement);

  my $statementElement = $xmlDoc->createElementNS(CMIS_NS, "statement");
  $statementElement->addChild($xmlDoc->createCDATASection($statement));
  $queryElement->appendChild($statementElement);

  foreach my $key (keys %params) {
    my $optionElement = $xmlDoc->createElementNS(CMIS_NS, $key);
    $optionElement->appendText($params{$key});
    $queryElement->appendChild($optionElement);
  }

  #_writeCmisDebug("query:\n".$xmlDoc->toString(1));

  return $xmlDoc;
}

=item getLatestChangeLogToken () -> $token

returns a token to ge use fetching a changes atom feed.

=cut

sub getLatestChangeLogToken {
  my $this = shift;

  unless ($this->getCapabilities()->{'Changes'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support change logs"); 
  }

  return $$this->getRepositoryInfo->{latestChangeLogToken};
}

=item getContentChanges(%params) -> $atomFeed

returns a AtomFeed containing ChangeEntry objects.

See CMIS specification document 2.2.6.2 getContentChanges

The following optional arguments are supported:

=over 4

=item changeLogToken 

=item includeProperties

=item includePolicyIDs

=item includeACL

=item maxItems

=back

You can get the latest change log token by inspecting the repository
info via Repository.getRepositoryInfo.

=cut

sub getContentChanges {
  my $this = shift;
  my %params = @_;
  
  #$params{changeLogToken} = $this->getLatestChangeLogToken() unless defined $params{changeLogToken};

  unless ($this->getCapabilities()->{'Changes'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support change logs"); 
  }

  my $changesUrl = $this->getLink(CHANGE_LOG_REL);
  my $result = $this->{client}->get($changesUrl, %params);

  # return the result set
  require WebService::Cmis::AtomFeed::ChangeEntries;
  return new WebService::Cmis::AtomFeed::ChangeEntries(repository=>$this, xmlDoc=>$result);
}

=item createDocument(
  $name, 
  folder=>$parentFolder,
  properties=>$propsList, 
  contentFile=>$filename,
  contentData=>$data, 
  contentType=>$type, 
) -> $cmisDocument

creates a new Document object in the parent folder provided or filed to the
Unfiled collection of the repository.

The method will attempt to guess the appropriate content type and encoding
based on the file. To specify it yourself, pass them in via the contentType and

To specify a custom object type, pass in a Property for cmis:objectTypeId
representing the type ID of the instance you want to create. If you do not pass
in an object type ID, an instance of 'cmis:document' will be created.

See CMIS specification document 2.2.4.1 createDument

=cut

sub createDocument {
  my $this = shift;
  my $name = shift;
  my %params = @_;

  my $parentFolder = delete $params{folder};
  my $properties = delete $params{properties};
  $properties = [] unless defined $properties;

  # construct properties
  require WebService::Cmis::Property;

  push @$properties, WebService::Cmis::Property::newString(
      id => 'cmis:name',
      value => $name,
    );

  my $foundObjectTypeId = 0;
  foreach my $prop (@$properties) {
    if ($prop->getId eq 'cmis:objectTypeId') {
      $foundObjectTypeId = 1;
      last;
    }
  }

  unless ($foundObjectTypeId) {
    push @$properties, WebService::Cmis::Property::newId(
      id => 'cmis:objectTypeId',
      value => 'cmis:document',
    );
  }

  # create the object
  return $this->createObject(
    $parentFolder, 
    properties=>$properties,
    %params,
  );
}


=item createFolder($name, folder=>$parentFolder, properties=>$propertyList, %params) -> $cmisFolder

creates a new CMIS Folder using the properties provided.

To specify a custom folder type, pass in a property called
cmis:objectTypeId representing the type ID
of the instance you want to create. If you do not pass in an object
type ID, an instance of 'cmis:folder' will be created.

  my $rootFolder = $repo->getRootFolder;

  my $subFolder = $rootFolder->createFolder(
    'My new folder', 
    summary => "This is my new test folder."
  );

  my $repo = $repo->createFolder(
    'My other folder', 
    folder => $rootFolder,
    summary => "This is my other test folder."
  );

See CMIS specification document 2.2.4.3 createFolder

=cut

sub createFolder {
  my $this = shift;
  my $name = shift;
  my %params = @_;

  my $parentFolder = delete $params{folder};

  my $properties = delete $params{properties};
  $properties = [] unless defined $properties;

  # construct properties
  require WebService::Cmis::Property;

  push @$properties,
    WebService::Cmis::Property::newString(
    id => 'cmis:name',
    value => $name,
    );

  my $foundObjectTypeId = 0;
  foreach my $prop (@$properties) {
    if ($prop->getId eq 'cmis:objectTypeId') {
      $foundObjectTypeId = 1;
      last;
    }
  }

  unless ($foundObjectTypeId) {
    push @$properties,
      WebService::Cmis::Property::newId(
      id => 'cmis:objectTypeId',
      value => 'cmis:folder',
      );
  }

  # create the object
  return $this->createObject(
    $parentFolder,
    properties => $properties,
    %params,
  );
}

=item createRelationship

TODO: This is not yet implemented.

=cut

sub createRelationship { throw WebService::Cmis::NotImplementedException; }

=item createPolicy

TODO: This is not yet implemented.

=cut

sub createPolicy { throw WebService::Cmis::NotImplementedException; }

=back

=head1 AUTHOR

Michael Daum C<< <daum@michaeldaumconsulting.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut


1;

