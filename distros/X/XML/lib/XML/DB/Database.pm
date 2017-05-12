package XML::DB::Database;
use strict;
use Carp;
use vars qw ($AUTOLOAD);

=head1 NAME

XML::DB::Database - Abstract class for extension by XML:SimpleDB drivers 

=head1 SYNOPSIS

  use XML::DB::Database;

=head1 DESCRIPTION

This is an abstract class implementing the interface Database from the XML:DB base specification. It should only be used indirectly, as superclass for a specific database driver which implements the Database interface. Examples are Exist.pm and Xindice.pm. 

=head1 BUGS

=head1 AUTHOR

	Graham Seaman
	CPAN ID: GSEAMAN
	graham@opencollector.org

=head1 COPYRIGHT

Copyright (c) 2002 Graham Seaman. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=head1 METHODS (all called indirectly by other modules)

=cut

=head2 getName

=over

I<Usage>     : getName()

I<Purpose>   : Returns the database name (eg. 'eXist')

I<Argument>  : None

I<Returns>   : String

=back

=cut

sub getName{
    my $self = shift;
    return $self->{'name'};
}

=head2 getName

=over

I<Usage>     : getConformanceLevel()

I<Purpose>   : Returns the conformance level of this implementation (see http://www.xmldb.org)

I<Argument>  : None

I<Returns>   : String

=back

=cut

sub getConformanceLevel{
    my $self = shift;
    return $self->{'conformanceLevel'};
}


=head2 getCollection

=over

I<Usage>     : $collection = getCollection($uri, $username, $passwd)

I<Purpose>   : Returns a Collection 

I<Argument>  : uri for collection, optional name and password

I<Returns>   : Collection

=back

=cut

sub getCollection{
    my ($self, $uri, $name, $passwd) = @_;
    my ($db, $url, $collectionName) = _parseURI($uri);
    
    my $collection = XML::DB::Collection->new($uri, $self);

return $collection;
}

=head2 acceptsURI

=over

I<Usage>     : if (db::acceptsURI(exist:://....)){ ...

I<Purpose>   : Returns true if database accepts URI starting with name (eg. 'eXist', 'Xindice')

I<Argument>  : A URI

I<Returns>   : Boolean

I<Comment>   : Broken. FIXME

=back

=cut

sub acceptsURI{
    my ($self, $uri) = @_;
    return $uri =~ m|^$self->{'name'}://|;
}

=head2 getProperty

=over

I<Usage>     : $property = getProperty($name)

I<Purpose>   : Returns named property

I<Argument>  : name of property

I<Returns>   : String or null

=back

=cut

sub getProperty{
    my ($self, $name) = @_;

    my $property = $self->{$name};
    return $property;
}

=head2 setProperty

=over

I<Usage>     : $property = setProperty($name, $value)

I<Purpose>   : Sets property to value

I<Argument>  : name and value
 
I<Returns>   : void

=back

=cut

sub setProperty{
    my ($self, $name, $value) = @_;

    $self->{$name} = $value;
}

=head2 new

=over

I<Usage>     : Should be called indirectly via DatabaseManager

I<Purpose>   : Constructor

=back

=cut
  

sub new{
	my ($class, $name) = @_;
	my $self = {
	    name => $name, 
	    prettyName => '',
	    location => '',
	    url => '',
	    proxy => '',
	    conformanceLevel => 1, #includes XUpdate for eXist :-)
	    interface => { 
		      	  createId => 1,
			  createCollection => 1,
			  dropCollection => 1,
			  listChildCollections => 1,
			  listCollections => 1,
			  queryCollection => 1,
			  getDocument => 1,
			  getDocumentCount => 1,
			  insertDocument => 1,
			  listDocuments => 1,
			  queryDocument => 1,
			  removeDocument => 1,
			  splitContents => 1,
			  update => 1,
			  updateResource => 1,
		      },
	};
	my $implementation = ucfirst(lc($name));
	$implementation = 'XML::DB::Database::' . $implementation;
	eval 'require ' . $implementation;
	die $@ if ($@);
	return new $implementation($self);
}

sub AUTOLOAD{
    my $self = shift;
    my ($method) = ($AUTOLOAD =~ m/::([^:]+)$/o );
    no strict 'refs';
    carp $AUTOLOAD . '(): unknown driver method' unless $self->{'interface'}->{$method};
    use strict 'refs';
    # give caller a chance to recover if driver doesnt support...
    die $AUTOLOAD . '(): not supported by this driver';
}

sub DESTROY{
}    
    


=head1 Interface

The following methods should be implemented by all concrete driver implementations. They are part of the internal working of this package, not part of the XML:DB specification. All can potentially throw exceptions.

=head2 createId($collectionName)

=over

I<Usage>     : $id = $driver->createId($collectionName)

I<Purpose>   : Creates a new unique OID for this collection.

I<Argument>  : collectionName The name of the collection including database  instance. 

I<Returns>   : The generated id 

=back

=cut

=head2 createCollection

=over

I<Usage>     : $driver->createCollection($parentCollection, $collectionName )

I<Purpose>   : Creates specified Collection

I<Arguments>  : 

=over 4

=item * $parentCollection - The name of the collection including database instance to create the collection.

=item * $collectionName The name of newly created collection.

=back

I<Returns>   : 1 on success 

=back

=cut

=head2 dropCollection

=over

I<Usage>     : $driver->dropCollection($collectionName )

I<Purpose>   : Deletes specified collection from the database

I<Argument>  : $collectionName - The name of the collection including database instance.

I<Returns>   : 1 on success 

=back

=cut

=head2 listChildCollections

=over

I<Usage>     : $collections = $driver->listChildCollections($collectionName )

I<Purpose>   : Lists all child collections under this collection.

I<Argument>  : $collectionName - The name of the collection including database instance.

I<Returns>   : Arrayref for the list of child collections. 

=back

=cut


=head2 queryCollection

=over

I<Usage>     : $xml = $driver->queryCollection($collectionName, $style, $query, \%namespaces)

I<Purpose>   : Executes a query against a collection

I<Arguments>  : 

=over 4

=item * $collectionName - The name of the collection including database instance.

=item * $style - XPath or XUpdate

=item * $query The query string to execute, should be in the proper syntax for the style specified.

=item * \%namespaces A Hashref containing namespace definitions. The key is the namespace prefix and the value is the namespace URI.

=back

I<Returns>   : The result of the query as XML.

=back

=cut

=head2 getDocument

=over

I<Usage>     :  $document = $driver->getDocument($collectionName, $id )

I<Purpose>   : Retrieves a document from the collection

I<Arguments>

=over 4

=item * $collectionName - The name of the collection including database instance.

=item * $id - The id of the document to retrieve

=back

I<Returns>   : The retrieved Document 

=back

=cut

=head2 getDocumentCount

=over

I<Usage>     : $count = getDocumentCount($collectionName )

I<Purpose>   : Returns the number of documents stored in this collection. 

I<Argument>  : $collectionName - The name of the collection including database instance.

I<Returns>   : The number of documents in the collection 

=back

=cut

=head2 insertDocument

=over

I<Usage>     : $id = insertDocument($collectionName, $content, $id )

I<Purpose>   : Inserts a new document into the collection

I<Arguments>  : 

=over 4 

=item * $collectionName - The name of the collection including database instance

=item *  $content - The Document to insert

=item *  $id - The id to insert the document under or the empty string if a new id should be generated automatically.

=back

I<Returns>   : The id of the inserted document. 

=back

=cut

=head2 listDocuments

=over

I<Usage>     : @documents = listDocuments($collectionName )

I<Purpose>   : Returns a set containing all documents in the collection.

I<Argument>  : $collectionName - The name of the collection including database instance.

I<Returns>   : Arrayref of document ids in the specified collection 

=back

=cut

=head2 queryDocument

=over

I<Usage>     : $xml = queryDocument($collectionName, $style, $query, %namespaces, $id )

I<Purpose>   : Executes a query against a Document in this collection

I<Arguments>  : 

=over 4

=item * $collectionName - The name of the collection including database instance.

=item * $style - XPath or XUpdate

=item * $query - The query string to execute, should be in the proper syntax for the style specified 

=item * \%namespaces - A Hashtable containing namespace definitions. The key is the namespace prefix and the value is the namespace URI

=item * $id the id of the document to query.

=back

I<Returns>   : The result of the query as XML. 

=back

=cut

=head2 removeDocument

=over

I<Usage>     : removeDocument($collectionName, $id )

I<Purpose>   : Deletes a document from the collection.

I<Arguments>  :

=over 4 

=item * $collectionName - The name of the collection including database instance.

=item *  $id - The id of the Document to delete

=back

I<Returns>   : 1 on success

=back

=cut
 
# needed for resourceSet

=head2 splitContents

=over

I<Usage>     : \@resources = $db->splitContents($data)

I<Purpose>   : Breaks fragments returned by query into separate elements to create a ResourceSet

I<Arguments>  : Data returned by query (string)

I<Returns>   : Array ref

=back

=cut

# Needed for XUpdateQueryService


=head2 update

=cut

=head2 updateResource

=cut




1; 

__END__


