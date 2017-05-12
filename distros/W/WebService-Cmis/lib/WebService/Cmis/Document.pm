package WebService::Cmis::Document;

=head1 NAME

WebService::Cmis::Document - Representation of a cmis document

=head1 DESCRIPTION

Document objects are the elementary information entities managed by the repository.
This class represents a document object as returned by a L<WebService::Cmis::Repository/getObject>.

See CMIS specification document 2.1.4 Document Object

Parent class: L<WebService::Cmis::Object>

=cut

use strict;
use warnings;
use WebService::Cmis qw(:collections :contenttypes :namespaces :relations :utils);
use WebService::Cmis::Object ();
use WebService::Cmis::NotImplementedException ();
use WebService::Cmis::NotSupportedException ();
use XML::LibXML qw(:libxml);
use Error qw(:try);
our @ISA = ('WebService::Cmis::Object');

our $CMIS_XPATH_CONTENT_LINK = new XML::LibXML::XPathExpression('//*[local-name() = "content" and namespace-uri() = "'.ATOM_NS.'"]/@src');
our $CMIS_XPATH_RENDITIONS = new XML::LibXML::XPathExpression('//*[local-name()="object" and namespace-uri()="'.CMISRA_NS.'"]/*[local-name()="rendition" and namespace-uri()="'.CMIS_NS.'"]');

=head1 METHODS

=over 4

=cut

# clear document-specific caches
sub _initData {
  my $this = shift;

  $this->SUPER::_initData();
  undef $this->{renditions};
}

=item checkOut() -> $pwc

performs a checkOut on this document and returns the
Private Working Copy (PWC), which is also an instance of
Document

See CMIS specification document 2.2.7.1 checkOut

=cut

sub checkOut {
  my $this = shift;

  require WebService::Cmis::Property;

  # get the checkedout collection URL
  my $checkoutUrl = $this->{repository}->getCollectionLink(CHECKED_OUT_COLL);
  throw Error::Simple("Could not determine the checkedout collection url.") unless defined $checkoutUrl;

  # get this document's object ID
  # build entry XML with it
  my $entryXmlDoc = $this->{repository}->createEntryXmlDoc(
    properties => [
      WebService::Cmis::Property::newId(
        id=>"cmis:objectId",
        queryName=>"cmis:objectId",
        value=>$this->getId
      )
    ]
  );

  #print STDERR "entryXmlDoc=".$entryXmlDoc->toString(1)."\n";

  # post it to to the checkedout collection URL
  my $result = $this->{repository}{client}->post($checkoutUrl, $entryXmlDoc->toString, ATOM_XML_ENTRY_TYPE);

  $this->{xmlDoc} = $result;
  $this->_initData;
  $this->reload;

  return $this;
}

=item isCheckedOut() -> $boolean

Returns true if the document is checked out.

=cut

sub isCheckedOut {
  my $this = shift;

  my $prop = $this->getProperties->{'cmis:isVersionSeriesCheckedOut'};
  return 0 unless defined $prop;
  return $prop->getValue;
}


=item getCheckedOutBy() -> $userId

returns the ID who currently has the document checked out.

=cut

sub getCheckedOutBy {
  my $this = shift;

  my $prop = $this->getProperties->{'cmis:versionSeriesCheckedOutBy'};
  return unless defined $prop;
  return $prop->getValue;
}

=item getPrivateWorkingCopy() -> L<$cmisDocument|WebService::Cmis::Document>

retrieves the object using the object ID in the property:
cmis:versionSeriesCheckedOutId then uses getObject to instantiate
the object.

=cut

sub getPrivateWorkingCopy {
  my $this = shift;

  my $pwcDocId = $this->getProperty('cmis:versionSeriesCheckedOutId');
  return unless $pwcDocId;
  return $this->{repository}->getObject($pwcDocId);
}

=item cancelCheckOut() -> L<$this|WebService::Cmis::Document>

cancels the checkout of this object by retrieving the Private Working
Copy (PWC) and then deleting it. After the PWC is deleted, this object
will be reloaded to update properties related to a checkout.

See CMIS specification document 2.2.7.2 cancelCheckOut

=cut

sub cancelCheckOut {
  my $this = shift;

  my $pwcDoc = $this->getPrivateWorkingCopy;
  $pwcDoc->delete if defined $pwcDoc;

  return $this->getLatestVersion;
}

=item checkIn($checkinComment, %params) -> $this

checks in this Document which must be a private
working copy (PWC).

See CMIS specification document 2.2.7.3 checkIn

The following optional arguments are supported:

=over 4

=item * major

=back

These aren't supported:

=over 4

=item * properties

=item * contentStream

=item * policies

=item * addACEs

=item * removeACEs

=back

TODO: support repositories without PWCUpdate capabilities

=cut

sub checkIn {
  my $this = shift;
  my $checkinComment = shift;

  # build an empty ATOM entry
  my $xmlDoc = new XML::LibXML::Document('1.0', 'UTF-8');
  my $entryElement = $xmlDoc->createElementNS(ATOM_NS, "entry");
  $xmlDoc->setDocumentElement($entryElement);

  # Get the self link
  # Do a PUT of the empty ATOM to the self link
  my $url = $this->getSelfLink;

  my $result = $this->{repository}{client}->put($url, $xmlDoc->toString, ATOM_XML_TYPE, 
    "checkin"=>'true', 
    "checkinComment"=>$checkinComment, 
    @_ # here goes our params
  );

  # reload the current object with the result
  $this->{xmlDoc} = $result;
  $this->_initData;
  $this->reload;

  return $this;
}

=item getContentLink(%params) -> $url

returns the source link to this document

The params are added to the url.

=cut

sub getContentLink {
  my $this = shift;
  my %params = @_;

  my $url = $this->_getDocumentElement->find($CMIS_XPATH_CONTENT_LINK);
  $url = $this->getLink('enclosure') unless defined $url;
  return unless defined $url;
  $url = "".$url;

  my $gotUrlParams = ($url =~ /\?/)?1:0;

  foreach my $key (keys %params) {
    if ($gotUrlParams) {
      $url .= '&';
    } {
      $url .= '?';
      $gotUrlParams = 1;
    }
    $url .= $key.'='._urlEncode($params{$key});
  }

  return $url;
}

=item getContentStream($streamId) -> $data

returns the CMIS service response from invoking the 'enclosure' link.
it will return the binary content of the document stored on the server.

The optional argument:

=over 4

=item * streamId: id of the content rendition (TODO: not implemented yet)

=back

See CMIS specification document 2.2.4.10 getContentStream

  my $doc = $repo->getObjectByPath("/User homes/jeff/sample.pdf");
  my $content = $doc->getContentStream;

  my $FILE;
  unless (open($FILE, '>', $name)) {
    die "Can't create file $name - $!\n";
  }
  print $FILE $text;
  close($FILE);


=cut

sub getContentStream {
  my $this = shift;
  
  my $url = $this->getContentLink;

  if ($url) {
    # if the url exists, follow that
    #print STDERR "url=$url\n";

    my $client = $this->{repository}{client};
    $client->GET($url, @_);

    my $code = $client->responseCode;
    return $client->responseContent if $code >= 200 && $code < 300;
    $client->processErrors;
  } else {
    # otherwise, try to return the value of the content element
    return $this->_getDocumentElement->findvalue("./*[local-name() = 'content' and namespace-uri() = '".ATOM_NS."']");
  }

  # never reach
  return;
}

=item getAllVersions(%params) -> $atomFeed

returns a AtomFeed` of document objects for the entire
version history of this object, including any PWC's.

See CMIS specification document 2.2.7.5 getAllVersions

The optional filter and includeAllowableActions are
supported.

TODO: is it worth caching these inside?

=cut

sub getAllVersions {
  my $this = shift;

  # get the version history link
  my $versionsUrl = $this->getLink(VERSION_HISTORY_REL);

  # invoke the URL
  my $result = $this->{repository}{client}->get($versionsUrl, @_);

  # return the result set
  require WebService::Cmis::AtomFeed::Objects;
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}

=item getRenditions(%params) -> %renditions

returns a hash of associated Renditions for the specified object. Only
rendition attributes are returned, not rendition stream.

The following optional arguments are currently supported:

=over 4

=item * renditionFilter

=item * maxItems

=item * skipCount

=back

A rendition has the following attributes:

=over 4

=item * streamId: Identifies the rendition stream

=item * mimetype: The MIME type of the rendition stream

=item * kind: A categorization String associated with the rendition
 
=item * length: The length of the rendition stream in bytes (optional)
 
=item * title: Human readable information about the rendition (optional)
 
=item * height: Typically used for 'image' renditions (expressed as pixels).
SHOULD be present if kind = C<cmis:thumbnail> (optional)
 
=item * width: Typically used for 'image' renditions (expressed as pixels).
SHOULD be present if kind = C<cmis:thumbnail> (optional)
 
=item * renditionDocumentId: If specified, then the rendition can also be accessed as
a document object in the CMIS services. If not set, then the rendition can only
be accessed via the rendition services. Referential integrity of this ID is
repository-specific. (optional)

=back

See CMIS specification document 2.1.4.2 Renditions

TODO: use <link rel="alternate" ... />

=cut

sub getRenditions {
  my $this = shift;
  my %params = @_;

  # if Renditions capability is None, return notsupported
  unless ($this->{repository}->getCapabilities->{'Renditions'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support Renditions");
  }

  unless ($this->{renditions}) {
    unless ($this->_getDocumentElement->exists($CMIS_XPATH_RENDITIONS)) {
      # reload including renditions
      $this->reload(renditionFilter=>'*');
    }
    my $elem = $this->_getDocumentElement;
    $this->{renditions} = ();
    foreach my $node ($elem->findnodes($CMIS_XPATH_RENDITIONS)) {
      my $rendition = ();
      foreach my $child ($node->childNodes) {
        next unless $child->nodeType == XML_ELEMENT_NODE;
        my $key = $child->localname;
        my $val = $child->string_value;
        #print STDERR "key=$key, value=".($val||'undef')."\n";
        $rendition->{$key} = $val;
      }
      $this->{renditions}{$rendition->{streamId}} = $rendition;
    }
  }

  return $this->{renditions};
}

=item getRenditionLink(%params)

returns a link to the documents rendition

Use the renditions properties to get a specific one (see L</getRenditions>):

=over 4

=item * streamId

=item * mimetype

=item * kind

=item * height

=item * width

=item * length

=item * title

=item * renditionDocumentId

=back

  my $doc = $repo->getObjectByPath("/User homes/jeff/sample.pdf");
  my $thumbnailUrl => $doc->getRenditionLink(kind=>"thumbnail");
  my $iconUrl = $doc->getRenditionLink(kind=>"icon", width=>16);

=cut

sub getRenditionLink {
  my $this = shift;
  my %params = @_;

  # if Renditions capability is None, return notsupported
  unless ($this->{repository}->getCapabilities->{'Renditions'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support Renditions");
  }

  my $renditions = $this->getRenditions;
  foreach my $rendi (values %$renditions) {
    my $found = 1;
    foreach my $key (keys %params) {
      if (defined $rendi->{$key} && $rendi->{$key} !~ /$params{$key}/i) {
        $found = 0;
        last;
      }
    }
    next unless $found;

    return $this->getContentLink(streamId=>$rendi->{streamId});
  }

  return;
}

=item getLatestVersion(%params) -> $document

returns a cmis Document representing the latest version in the version series.

See CMIS specification document 2.2.7.4 getObjectOfLatestVersion

The following optional arguments are supported:

=over 4

=item * major

=item * filter

=item * includeRelationships

=item * includePolicyIds

=item * renditionFilter

=item * includeACL

=item * includeAllowableActions

=back

  $latestDoc = $doc->getLatestVersion;
  $latestDoc = $doc->getLatestVersion(major=>1);

  print $latestDoc->getProperty("cmis:versionLabel")."\n";

=cut

sub getLatestVersion {
  my $this = shift;
  my %params = @_;
        
  my $major = delete $params{major};
  $params{returnVersion} = $major?'latestmajor':'latest';

  $this->_initData;

  $params{id} = $this->getProperty("cmis:versionSeriesId");
  return $this->reload(%params);
}

=item copy($targetFolder, $propertyList, $versionState) -> $cmisDocument

TODO: This is not yet implemented.

Creates a document object as a copy of the given source document in the (optionally) 
specified location. 

The $targetFolder specifies the folder that becomes the parent
of the new document. This parameter must be specified if the repository does not
have the "unfiling" capability.

The $propertyList is a list of WebService::Cmis::Property objects optionally specifieds
the propeties about to change in the newly created Document object.

Valid values for $versionState are:

=over 4

=item * none: the document is created as a non-versionable object

=item * checkedout: the document is created in checked-out state

=item * major (default): the document is created as a new major version

=item * minor: the document is created as a minor version

=back

The following optional arguments are not yet supported:

=over 4

=item * policies

=item * addACEs

=item * removeACEs

=back

See CMIS specification document 2.2.4.2 (createDocumentFromSource)

=cut

sub copy { throw WebService::Cmis::NotImplementedException; }

=item getPropertiesOfLatestVersion

TODO: This is not yet implemented.

=cut

sub getPropertiesOfLatestVersion { throw WebService::Cmis::NotImplementedException; }

=item setContentStream(%params) -> $this

This sets the content stream of a document.

The following parameters are supported:

=over 4

=item * contentFile: the absolute path to the file to be used.

=item * contentData: the data to be posted to the documents content stream link.
use either C<contentFile> or C<contentData>. 

=item * contentType: the mime type of the data. will be guessed automatically if not specified manually.

=item * overwriteFlag: if 'true' (default), replace the existing content stream.
if 'false', set the input contentStream if the object currently does not have a content-stream.

=item * changeToken

=back

See CMIS specification document 2.2.4.18 setContentStream

=cut

sub setContentStream { 
  my $this = shift;
  my %params = @_;

  my $contentStreamUpdatability = $this->{repository}->getCapabilities->{'ContentStreamUpdatability'};
  #print STDERR "contentStreamUpdatability=$contentStreamUpdatability\n";

  throw WebService::Cmis::NotSupportedException("This repository does not allow to set the content stream")
    if $contentStreamUpdatability eq 'none';

  my $contentFile = delete $params{contentFile};
  my $contentData = delete $params{contentData};
  my $contentType = delete $params{contentType};

  unless (defined $contentData) {
    my $fh;

    open($fh, '<', $contentFile) 
      or throw Error::Simple("can't open file $contentFile"); # SMELL: use a custom exception

    local $/ = undef;# set to read to EOF
    $contentData = <$fh>;
    close($fh);
    $contentData = '' unless $contentData; # no undefined
  }

  unless (defined $contentType) {

    # get the file mage used for checking
    require File::MMagic;
    my $fileMage = new File::MMagic;

    $contentType = $fileMage->checktype_contents($contentData);

    # contentType fallback
    $contentType = 'application/binary' unless defined $contentType;
  }


  # SMELL: not sure whether we need to encode or not
  #require MIME::Base64;
  #$contentData = MIME::Base64::encode_base64($contentData);

  my $url = $this->getContentLink;
  throw Error::Simple("Can't find content link for ".$this->getId) unless $url;

  # SMELL: CMIS specification document 2.2.4.18 and 3.1.9 don't agree whether to return the new object Id or not.
  # In addition it is not clear whether setContentStream should create a new revision or not.
  # So we make sure the document is checked out and will create a new minor version at least.

  if ($contentStreamUpdatability eq 'pwconly') {
    $this->checkOut unless $this->isCheckedOut;
  }

  my $result = $this->{repository}{client}->put($url, $contentData, $contentType, %params) || '';

  # reload with this result
  if (defined $result && $result ne '') {
    $this->{xmlDoc} = $result;
    $this->_initData;
  }

  $this->reload;

  # make sure this is checked in
  if ($contentStreamUpdatability eq 'pwconly') {
    $this->checkIn("setting content stream", major=>0) if $this->isCheckedOut;
  }

  return $this;
}

=item deleteContentStream

TODO: This is not yet implemented.

See CMIS specification document 2.2.4.17 deleteContentStream

=cut

sub deleteContentStream { throw WebService::Cmis::NotImplementedException; }

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
