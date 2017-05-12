package WebService::Cmis::AtomFeed;

=head1 NAME

WebService::Cmis::AtomFeed - Representation of an Atom feed.

=head1 DESCRIPTION

This class is subclassed to further specify the type of entries in this collection.

Sub-classes:

=over 4

=item * L<WebService::Cmis::AtomFeed::Objects>

=item * L<WebService::Cmis::AtomFeed::ChangeEntries> 

=item * L<WebService::Cmis::AtomFeed::ObjectTypes>

=back

Sub-classes must implement <L/newEntry> to specify how to instantiate objects of this feed.

=cut

use strict;
use warnings;
use WebService::Cmis qw(:namespaces :relations :utils);
use XML::LibXML ();

our $CMIS_XPATH_ENTRY = new XML::LibXML::XPathExpression('./*[local-name() = "entry"]');
our $CMIS_XPATH_TITLE = new XML::LibXML::XPathExpression('./*[local-name() = "title" and namespace-uri() ="'.ATOM_NS.'"]');
our $CMIS_XPATH_UPDATED = new XML::LibXML::XPathExpression('./*[local-name() = "updated" and namespace-uri() ="'.ATOM_NS.'"]');
our $CMIS_XPATH_GENERATOR = new XML::LibXML::XPathExpression('./*[local-name() = "generator" and namespace-uri() ="'.ATOM_NS.'"]');
our $CMIS_XPATH_NUMITEMS = new XML::LibXML::XPathExpression('./*[local-name() = "numItems" and namespace-uri() ="'.CMISRA_NS.'"]');
our $CMIS_XPATH_PAGESIZE = new XML::LibXML::XPathExpression('./*[local-name() = "itemsPerPage" and namespace-uri() ="'.OPENSEARCH_NS.'"]');
our $CMIS_XPATH_TOTALRESULTS = new XML::LibXML::XPathExpression('./*[local-name() = "totalResults" and namespace-uri() ="'.OPENSEARCH_NS.'"]');

=head1 METHODS

=over 4

=item new(%params)

Create a new WebService::Cmis::AtomFeed object. 

=cut

sub new {
  my $class = shift;

  my $this = bless({@_ }, $class);

  throw Error::Simple("no xmlDoc in constructor") unless defined $this->{xmlDoc};

  $this->_initData;

  return $this;
}

sub _initData {
  my $this = shift;

  $this->{index} = 0; 
  $this->{entries} = undef;
  $this->{title} = undef;
  $this->{updated} = undef;
  $this->{generator} = undef;
  $this->{totalResults} = undef;
  $this->{pageSize} = undef;
}

sub DESTROY {
  my $this = shift;

  $this->_initData;

  $this->{repository} = undef;
  $this->{xmlDoc} = undef;
}

=item getLink($relation) -> $href

returns the link found in the feed's XML for the specified relation

=cut

sub getLink {
  my ($this, $relation) = @_;

  my ($linkNode) = $this->{xmlDoc}->documentElement->findnodes('./*[local-name() = "link" and @rel="'.$relation.'"][1]/@href');
  return $linkNode->value if $linkNode;
}

# given a specified $relation, does a get using that link (if one exists)
# and then converts the resulting XML into a list of
# AtomEntry objects or its appropriate sub-type.
# The results are kept around to facilitate repeated calls without moving
# the cursor.
sub _getPage {
  my ($this, $relation) = @_;

  my $link = $this->getLink($relation);
  return unless $link;

  #print STDERR "getPage($link)\n";

  $this->{xmlDoc} = $this->{repository}{client}->get($link);

  $this->{entries} = undef;
  $this->{index} = 0;

  return $this->_getPageEntries;
}

# returns a list of all AtomEntries on the current page
sub _getPageEntries {
  my $this = shift;

  unless (defined $this->{entries}) {
    my @entries = $this->{xmlDoc}->documentElement->findnodes($CMIS_XPATH_ENTRY);
    $this->{entries} = \@entries;
  }

  return $this->{entries};
}

=item newEntry($xmlDoc) -> $atomEntry

creates an item from an xml fragment part of this atom feed. this virtual method
must be implemented by subclasses of AtomFeed.
name to be used for all entries

=cut

sub newEntry {
  throw Error::Simple("virtual method not implemented");
}

=item getNext -> $nextAtomEntry

returns the next AtomEnrty in this feed
or undef if we hit the end of the list

=cut 

sub getNext {
  my $this = shift;

  my $nrEntries = scalar(@{$this->_getPageEntries});

  if ($this->{index} >= $nrEntries) {
    #my $link = $this->getLink(NEXT_REL);
    #print STDERR "fetching next page from $link\n";
    return unless $this->_getPage(NEXT_REL);
  } else {
    #print STDERR "using current page\n";
  }

  my $result = $this->{entries}->[$this->{index}];
  return unless $result;

  $this->{index}++;

  #print STDERR "newEntry ($this)\n";
  return $this->newEntry($result);
}

=item getPrev -> $prevAtomEntry

returns the previous AtomEnrty in this feed
or undef if we hit the beginning of the list

=cut 

sub getPrev {
  my $this = shift;

  $this->{index}--;

  if ($this->{index} < 0) {
    return unless $this->_getPage(PREV_REL);

    my $nrEntries = scalar(@{$this->_getPageEntries});
    return unless $nrEntries;
    
    $this->{index} = $nrEntries-1;
  }

  my $result = $this->_getPageEntries->[$this->{index}];
  return unless $result;

  return $this->newEntry($result);
}

=item getFirst -> $firstAtomEntry

returns the first AtomEntry of the feed.

=cut 

sub getFirst {
  my $this = shift;

  $this->rewind;
  return $this->newEntry($this->_getPageEntries->[$this->{index}]);
}

=item getLast -> $lastAtomEntry

returns the last AtomEntry of the feed.

=cut 

sub getLast {
  my $this = shift;

  $this->fastforward;
  $this->{index}--;
  return $this->newEntry($this->_getPageEntries->[$this->{index}]);
}

=item fastforward 

fetches the last page of the feed and sets the index to the last entry on that
page. This is the kind of oposite of rewind().  This only works if the
repository returns a "last" link.

=cut 

sub fastforward {
  my $this = shift;

  $this->_getPage(LAST_REL);
  $this->{index} = scalar(@{$this->_getPageEntries});
}

=item rewind 

fetches the first page of the feed again and resets the counter
so that the next call to getNext() will return the first AtomEntry
in the feed again

=cut

sub rewind {
  my $this = shift;

  $this->_getPage(FIRST_REL);
  $this->{index} = 0;
}

=item getTitle -> $title

getter for the object's atom:title property.

=cut

sub getTitle {
  my $this = shift;

  unless (defined $this->{title}) {
    $this->{title} = $this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_TITLE);
  }

  return $this->{title};
}

=item getUpdated -> $epoch

getter for the object's atom:updated property.

=cut

sub getUpdated {
  my $this = shift;

  unless (defined $this->{updated}) {
    require WebService::Cmis::Property;
    $this->{updated} = WebService::Cmis::Property::parseDateTime($this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_UPDATED));
  }

  return $this->{updated};
}

=item getGenerator -> $string

getter for the object's atom:generator property.

=cut

sub getGenerator {
  my $this = shift;

  unless (defined $this->{generator}) {
    $this->{generator} = $this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_GENERATOR);
  }

  return $this->{generator};
}


=item getSize -> $integer

get the total number of items in the result set. it first tries to read the cmisra:numItems property.
if that's not present the opensearch:totalResults elemt is checked

=cut

sub getSize {
  my $this = shift;

  unless (defined $this->{totalResults}) {
    $this->{totalResults} = 
      $this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_TOTALRESULTS) || 
      $this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_NUMITEMS) || 
      scalar(@{$this->_getPageEntries});
  }

  return $this->{totalResults};
}

=item getPageSize -> $integer

returns the size of a page in the result set. this should equal the maxItem value if set in a query

=cut

sub getPageSize {
  my $this = shift;

  unless (defined $this->{pageSize}) {
    $this->{pageSize} = 
      $this->{xmlDoc}->documentElement->findvalue($CMIS_XPATH_PAGESIZE) || 
      scalar(@{$this->_getPageEntries});
  }

  return $this->{pageSize};
}


=item toString()

return a string representation of this object

=cut

sub toString {
  my $this = shift;

  my @result = ();
  foreach my $elem (@{$this->_getPageEntries}) {
    my $id = $elem->findvalue('./cmisra:object/cmis:properties/cmis:propertyId[@propertyDefinitionId="cmis:objectId"]');
    next unless $id;
    my $name = $elem->findvalue('./cmisra:object/cmis:properties/cmis:propertyString[@propertyDefinitionId="cmis:name"]');
    push @result, "$id ($name)";
  }

  return $this->getTitle.': '.join(", ", @result);
}


=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
