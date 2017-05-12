package WebService::Cmis::Folder;

=head1 NAME

WebService::Cmis::Folder - Representation of a cmis folder

See CMIS specification document 2.1.5 Folder Object

=head1 DESCRIPTION

This is a container object that holds other objects thus establishing a
hierarchical structure.

Parent class: L<WebService::Cmis::Ojbect>

=cut

use strict;
use warnings;
use WebService::Cmis qw(:relations :contenttypes :utils);
use WebService::Cmis::Object();
use WebService::Cmis::NotImplementedException ();
use WebService::Cmis::NotSupportedException ();
use WebService::Cmis::AtomFeed::Objects ();
use Error qw(:try);
our @ISA = ('WebService::Cmis::Object');

=head1 METHODS

=over 4

=cut

=item getChildren(%params) -> $atomFeed

returns a paged AtomFeed. The result set contains a list of objects for each
child of the Folder. The actual type of the object returned depends on the
object's CMIS base type id.  For example, the method might return a list that
contains both Document objects and Folder objects.

See CMIS specification document 2.2.3.1 getChildren

The following optional arguments are supported:

=over 4

=item * maxItems

=item * skipCount

=item * orderBy

=item * filter

=item * includeRelationships

=item * renditionFilter

=item * includeAllowableActions

=item * includePathSegment

=back

=cut

sub getChildren {
  my $this = shift;

  # get the appropriate 'down' link
  my $childrenUrl = $this->getChildrenLink();

  # invoke the URL
  my $result = $this->{repository}{client}->get($childrenUrl, @_); # here go the params

  #print STDERR "### getting children for\n".$result->toString(1)."\n###\n";

  # return the result set
  require WebService::Cmis::AtomFeed::Objects;
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}

=item getChildrenLink() -> $href

gets the Atom link that knows how to return this object's children.

=cut

sub getChildrenLink {
  my $this = shift;

  my $url = $this->getLink(DOWN_REL, ATOM_XML_FEED_TYPE_P, 1);

  unless ($url) {
    if ($ENV{CMIS_DEBUG}) {
      _writeCmisDebug("Coulnd not find the children url in\n".$this->{xmlDoc}->toString(1)."\n");
    }
    throw Error::Simple("Could not find the children url"); # SMELL: do a custom exception
  }

  return $url;
}

=item getDescendantsLink -> $href

returns the 'down' link of type CMIS_TREE_TYPE

=cut

sub getDescendantsLink {
  my $this = shift;

  my $url = $this->getLink(DOWN_REL, CMIS_TREE_TYPE_P, 1);

  throw Error::Simple("Could not find the descendants url") unless $url; # SMELL: do a custom exception

  return $url;
}

=item getDescendants(%params) -> $atomFeed

gets the descendants of this folder. The descendants are returned as
a paged result set object. The result set contains a list of
cmis objects where the actual type of each object
returned will vary depending on the object's base type id. 

See CMIS specification document 2.2.3.2 getDescendants

The following optional argument is supported:

=over 4

=item * depth: 
Use depth=-1 for all descendants, which is the default if no
depth is specified.

=item * filter

=item * includeAllowableActions

=item * includePathSegment

=item * includeRelationships

=item * renditionFilter

=item * types

=back

=cut

sub getDescendants {
  my $this = shift;
  my %params = @_;

  unless ($this->{repository}->getCapabilities()->{'GetDescendants'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support getDescendants");
  }

  # default the depth to -1, which is all descendants
  $params{depth} = -1 unless defined $params{depth};

  # get the appropriate 'down' link
  my $descendantsUrl = $this->getDescendantsLink;

  # invoke the URL
  my $result = $this->{repository}{client}->get($descendantsUrl, %params);

  # return the result set
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}

=item getFolderParent -> $folderObj

See CMIS specification document 2.2.3.4 getFolderParent

=cut

sub getFolderParent {
  my $this = shift;

  # get the appropriate 'up' link
  my $parentUrl = $this->getLink(UP_REL, undef, 1);

  return unless $parentUrl;

  # invoke the URL
  my $result = $this->{repository}{client}->get($parentUrl, @_);

  my $nodeName = $result->documentElement->nodeName;
  $nodeName =~ s/^([^:]+)://;

  # return the result
  return new WebService::Cmis::Folder(repository => $this->{repository}, xmlDoc => $result)
    if $nodeName eq 'entry';

  # some vendors (e.g. nuxeo) return a one-element AtomFeed instead of an
  # AtomEntry even though the specs are clear in that respect

  throw Error::Simple("invalid result getting a folder parent") 
    unless $nodeName eq 'feed';

  my $feed = new WebService::Cmis::AtomFeed::Objects(
    repository => $this->{repository},
    xmlDoc => $result
  );

  return $feed->getFirst;
}

=item getFolderTree -> $atomFeed

unlike getChildren or getDescendants this method returns only the descendant
objects that are folders. The results do not include the current folder.

See CMIS specification document 2.2.3.3 getFolderTree

The following optional arguments are supported:

=over 4

=item * depth

=item * filter

=item * includeRelationships

=item * renditionFilter

=item * includeAllowableActions

=item * includePathSegment

=back

=cut

sub getFolderTree {
  my $this = shift;

  # Get the descendants link and do a GET against it
  my $url = $this->getLink(FOLDER_TREE_REL, undef, 1);

  unless (defined $url) {
    throw Error::Simple("Unable to determin folder tree link"); # SMELL: use custom exceptions
  }

  # invoke
  my $result = $this->{repository}{client}->get($url, @_);

  # return the result set
  require WebService::Cmis::AtomFeed::Objects;
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}


=item createDocument(
  $name, 
  properties=>$propsList, 
  contentFile=>$filename,
  contentData=>$data, 
  contentType=>$type, 
  contentEncoding=>$encoding,
  %params
) -> $cmisDocument

creates a new Document object in the current Folder using
the properties provided.

See Repository::createDocument

=cut

sub createDocument {
  my $this = shift;
  my $name = shift;

  return $this->{repository}->createDocument($name, folder=>$this, @_);
}

=item createFolder(
  $name, 
  properties=>$propertyList,
  %params
) -> $cmisFolder

creates a new CMIS Folder using the properties provided.

To specify a custom folder type, pass in a property called
cmis:objectTypeId representing the type ID
of the instance you want to create. If you do not pass in an object
type ID, an instance of 'cmis:folder' will be created.


=cut

sub createFolder {
  my $this = shift;
  my $name = shift;

  return $this->{repository}->createFolder($name, folder=>$this, @_);
}

=item addObject($obj)

Adds an existing fileable non-folder object to a folder.
This is the same as moving the object to this folder. See
Object::moveTo.

See CMIS specification document 2.2.5.1 addObjectToFolder

=cut

sub addObject {
  return $_[1]->moveTo($_[0]);
}

=item removeObject($obj)

removes an object from this folder. this is done by posting it
to the unfiled collection, providing the current folderId. 
See Object::unfile

See CMIS specification document 2.2.5.2

=cut

sub removeObject {
  return $_[1]->unfile($_[0]);
}

=item deleteTree

Deletes the folder and all of its descendant objects.

  my $resultSet = $folder->getDescendants()
  my $size = $resultSet->getSize();
  my $failedToDelete = $folder.deleteTree()
  if ($failedToDelete) {
    ...
  }
  

The following optional arguments are supported:

=over 4

=item * allVersions

=item * unfileObjects

=item * continueOnFailure

=back

See CMIS specification document 2.2.4.15

=cut

sub deleteTree { 
  my $this = shift;

  unless ($this->{repository}->getCapabilities()->{'GetDescendants'}) {
    throw WebService::Cmis::NotSupportedException("This repository does not support getDescendants");
  }

  my $url = $this->getDescendantsLink;
  my $result = $this->{repository}{client}->delete($url, @_); # here go the params

  return unless $result;

  # failedToDelete: A list of identifiers of objects in the folder tree that were not deleted.
  require WebService::Cmis::AtomFeed::Objects;
  return new WebService::Cmis::AtomFeed::Objects(repository=>$this->{repository}, xmlDoc=>$result);
}


=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
