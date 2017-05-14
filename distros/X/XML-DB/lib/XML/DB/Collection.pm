package XML::DB::Collection;
use strict;
use Carp;
use XML::DB::ErrorCodes;
use XML::DB::Resource;
use XML::DB::Service;

BEGIN {
    use vars qw ($VERSION);
    $VERSION     = 0.01;

}

=head1 NAME

XML::DB::Collection - A collection of data returned from the db.

=head1 SYNOPSIS

eval{
    $dbm = new XML::DB::DatabaseManager();
    $dbm->registerDatabase($driver);
    $col = $dbm->getCollection("xmldb:$driver:$url/db/test");
    };

if ($@){
    die $@;
}

$name = $col->getName();
 
if ($col->isOpen()){  # always true unless explicitly closed 
    eval{
	$count = $col->getChildCollectionCount();
	$list_ref = $col->listChildCollections();
	$child_collection = $col->getChildCollection($child_name);
	$parentCollection = $col->getParentCollection();
	
	$new_id = $col->createId();
	$new_resource = $col->createResource($new_id, 'XMLResource');
	$col->storeResource($new_resource);
	$col->removeResource($resource);
	
	$resources = $col->getResourceCount();
	$resource = $col->getResource($id);
	
	$list_ref = $col->getServices();
	$service = $col->getService('XPathQueryService', '1.0');
	
	$col->setProperty($name, $value);
	$property = $col->getProperty($name);
	
	$col->close();
    };
    die $@ if ($@);
}

=head1 DESCRIPTION

This class implements the interface Collection from the XML:DB base specification. The initial Collection must be obtained from the DatabaseManager; after that, Collections can also be obtained from the CollectionManager service or from the initial Collection itself.

Collections are hierarchical, with a parent and possibly children. The Collection is the main route to access actual documents in the database: it provides access to Resources (which are abstractions of documents or document fragments) and Services (XPath queries, XUpdate commands, and the CollectionManager service). A collection is an analog to a table in a relational DB, or a directory in a file-system. 

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

XML::DB::DatabaseManager, XML::DB::Resource.

=head1 PUBLIC METHODS

=cut


=head2 close

=over

I<Usage>     : $col->close()

I<Purpose>   : Releases all resources used by the Collection. Here simply sets a flag.

I<Argument>  : None

I<Returns>   : void

=back

=cut

sub close{
    my $self = shift;
    $self->{'collectionClosed'} = 1;
}

=head2 createId

=over

I<Usage>     : $newId = $col->createId()

I<Purpose>   : Creates a new ID unique within the context of the Collection

I<Argument>  : None

I<Returns>   : new ID string

I<Throws>    : DRIVER_ERROR, COLLECTION_CLOSED 


=back

=cut

sub createId{
    my $self = shift;
    my $id;
    die "COLLECTION_CLOSED: Collection::createId" if $self->{'collectionClosed'};
    eval{
	$id = $self->{'driver'}->createId($self->{'path'});
    };
    die $@."Collection::createId()" if ($@);
    return $id;
}

=head2 createResource

=over

I<Usage>     : $resource = $col->createResource($id, $type)

I<Purpose>   : Creates a new empty Resource with the provided id. 

I<Argument>  : Type may be 'XMLresource' or 'BinaryResource'. The id must be unique for the collection; if null, a new id will be generated.

I<Returns>   : Resource

I<Comments>  : BinaryResource not implemented 

I<Throws> : COLLECTION_CLOSED

=back

=cut

sub createResource{
    my ($self, $id, $type) = @_;
    die "COLLECTION_CLOSED: Collection::createId" if $self->{'collectionClosed'};
    my $resource = new XML::DB::Resource($id, $id, $self, $type);
    return $resource;
}

=head2 getChildCollection

=over

I<Usage>     : $collection = $col->getChildCollection($name)

I<Purpose>   : Returns a Collection for the named child collection

I<Argument>  : None

I<Returns>   : Collection or null

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub getChildCollection{
    my ($self, $name) = @_;
    die "COLLECTION_CLOSED: Collection::getChildCollection($name)" if $self->{'collectionClosed'};
    my $childCol;
    eval{
	my $kids = $self->listChildCollections();
	my $found = 0;
	foreach(@{$kids}){
	    if ($name eq $_){
		$found = 1;
		last;
	    }
	}
	if (! $found){
	    return undef;
	}
	$childCol = new XML::DB::Collection($self->{'driver'}, $self->{'path'}, $name);
    };
    if ($@){ 
        die $@."Collection::getChildCollection($name)";
    }
  return $childCol;
}

=head2 getChildCollectionCount

=over

I<Usage>     : $no = $col->getChildCollectionCount()

I<Purpose>   : Returns the number of collections under this collection (may be 0)

I<Argument>  : None

I<Returns>   : Number

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub getChildCollectionCount{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::getChildCollectionCount()" if $self->{'collectionClosed'};
    my $list;
    eval{
	$list = $self->{'driver'}->listChildCollections($self->{'path'});
    };
    if ($@){
	die $@."Collection::getChildCollectionCount()";
    }
    if (ref($list) eq 'ARRAY'){
	return scalar(@{$list});
    }
    else{
	return 0;
    }
}

=head2 getName

=over

I<Usage>     : $name = $col->getName()

I<Purpose>   : Returns the name of this collection 

I<Argument>  : None

I<Returns>   : String
  

=back

=cut

sub getName{
    my $self = shift;

    return $self->{'collectionName'};
}

=head2 getParentCollection

=over

I<Usage>     : $parentCollection = $col->getParentCollection()

I<Purpose>   : Returns the parent of this collection (undef if none) 

I<Argument>  : None

I<Returns>   : Collection or undef

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub getParentCollection{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::getParentCollection" if $self->{'collectionClosed'};
    if ($self->{'collectionName'} !~ /\w+/){
	return undef; # this is the root collection (/db)
    }
    my $database = $self->{'database'};
    $database =~ s|/([^/]*)$||;
    my $parent = $1 || undef;
    unless ($parent =~ /\w+/){
	return undef;
    }
    my $parentCol;
    eval{
	$parentCol = new XML::DB::Collection($self->{'driver'}, $database, $parent);
    };
    if ($@){ 
        die $@."Collection::getParentCollection()";
    }
  return $parentCol;
}

=head2 getResource

=over

I<Usage>     : $resource = $col->getResource($id)

I<Purpose>   : Returns the resource with the given id from the database 

I<Argument>  : $id

I<Returns>   : Resource or null

I<Throws> : COLLECTION_CLOSED

=back

=cut

sub getResource{
    my ($self, $id) = @_;
    die "COLLECTION_CLOSED: Collection::createId" if $self->{'collectionClosed'};
    return new XML::DB::Resource($id, undef, $self, 'XMLResource');
}

=head2 getResourceCount

=over

I<Usage>     : $no = $col->getResourceCount()

I<Purpose>   : Returns the number of resources currently stored in the collection or zero if empty 

I<Argument>  : None 

I<Returns>   : Number

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub getResourceCount{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::getResourceCount()" if $self->{'collectionClosed'};
    if ($self->{'collectionName'} !~ /\w+/){
	return 0; # this is the root collection (/db)
    }
    my $count;
    eval{
	$count = $self->{'driver'}->getDocumentCount($self->{'path'});
    };
    if ($@){
	die $@."Collection::getResourceCount()";
    }
    return $count;
}

=head2 getService

=over

I<Usage>     : $service = $col->getService($name, $version)

I<Purpose>   : Returns the Service with the given name and version 

I<Argument>  : Name of service and version (currently always 1.0)

I<Returns>   : Service or null if does not exist
  
I<Throws> : COLLECTION_CLOSED

=back

=cut

sub getService{
    my ($self, $name, $version) = @_;
    die "COLLECTION_CLOSED: Collection::getService($name)" if $self->{'collectionClosed'};
    my $service = new XML::DB::Service($self, $name, $version) or return undef;

    return $service;
}

=head2 getServices

=over

I<Usage>     : $list = $col->getServices()

I<Purpose>   : Returns a list of names of services known to the Collection 

I<Argument>  : None 

I<Returns>   : Array of strings (may be empty)

I<Throws> : COLLECTION_CLOSED

=back

=cut

sub getServices{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::getServices()" if $self->{'collectionClosed'};
    return $self->{'services'};
}

=head2 isOpen

=over

I<Usage>     : if ($col->isOpen()){ ...

I<Purpose>   : Tests if Collection is open 

I<Argument>  : None

I<Returns>   : Boolean

=back

=cut

sub isOpen{
    my $self = shift;

    return ! $self->{'collectionClosed'};
}

=head2 listChildCollections

=over

I<Usage>     : $list = $col->listChildCollections()

I<Purpose>   : Returns a list of names of children of this collection 

I<Argument>  : None

I<Returns>   : Array of strings (may be empty)

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub listChildCollections{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::listChildCollections" if $self->{'collectionClosed'};
    my $list;
    eval{
	$list = $self->{'driver'}->listChildCollections($self->{'path'});
    };
    if ($@){
	die $@."Collection::listChildCollections()";;
    }
	
    return $list;
}

=head2 listResources

=over

I<Usage>     : $list = $col->listResources()

I<Purpose>   : Returns a list of ids of all resources in the Collection 

I<Argument>  : None

I<Returns>   : Array of strings 

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub listResources{
    my $self = shift;
    die "COLLECTION_CLOSED: Collection::listResources()" if $self->{'collectionClosed'};
    my $list = ();
    return $list if ($self->{'collectionName'} !~ /\w+/); # root coll contains none
    eval{
	$list = $self->{'driver'}->listDocuments($self->{'path'});
    };
    if ($@){ 
	die $@."Collection::listResources()";
    }
    return $list;
}

=head2 removeResource

=over

I<Usage>     : $col->removeResource($resource)

I<Purpose>   : Removes given resource from database 

I<Argument>  : Resource 

I<Returns>   : void
 
I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub removeResource{
    my ($self, $resource) = @_;
    die "COLLECTION_CLOSED: Collection::removeResource()" if $self->{'collectionClosed'};
    my $id = $resource->getDocumentId();
    eval{
	$self->{'driver'}->removeDocument($self->{'path'}, $id);
    };
    if ($@){ # catch
	die $@."Collection::removeResource()";
    }
}

=head2 storeResource

=over

I<Usage>     : $col->storeResource($resource)

I<Purpose>   : Stores resource in database. Updates the resource if it already exists.

I<Argument>  : Resource

I<Returns>   : void

I<Throws> : COLLECTION_CLOSED, DRIVER_ERROR

=back

=cut

sub storeResource{
    my ($self, $resource) = @_;
    die "COLLECTION_CLOSED: Collection::storeResource()" if $self->{'collectionClosed'};
    die "VENDOR_ERROR: The root collection cannot store documents at: Collection::storeResource()" if ($self->{'collectionName'} !~ /\w+/);

    eval { # try
	$self->{'driver'}->insertDocument($self->{'path'}, $resource->getContent(), $resource->getDocumentId());
    };
    if ($@){ 
	print $@."Collection::storeResource()";
    }
}

=head2 getProperty

=over

I<Usage>     : $property = $col->getProperty($name)

I<Purpose>   : Returns named property

I<Argument>  : None 

I<Returns>   : String or null

=back

=cut

sub getProperty{
    my ($self, $name) = @_;

    return $self->{$name};
}

=head2 setProperty

=over

I<Usage>     : $col->setProperty($name, $value)

I<Purpose>   : Sets property to value

I<Argument>  : Name and value of property
 
I<Returns>   : void

=back

=cut

sub setProperty{
    my ($self, $name, $value) = @_;

    $self->{$name} = $value;
}

=head2 new

=over

I<Usage>    : Never called directly by user (see synopsys for creation of Collections)
  
I<Purpose>  : Constructor

=back

=cut
  
sub new{
	my ($class, $driver, $database, $collectionName) = @_;
	my $path;
	# allow for root collection (no trailing slash wanted)
	if ($collectionName =~ /\w+/){
	    $path  = $database .'/'. $collectionName;
	}
	else{
	    $path = $database;
	}
	my $self = {
	          collectionName => $collectionName || '',
		  driver => $driver,
		  database => $database,
		  path => $path,
		  url => $driver->{'location'},
		  # temporary hack - should read directory to get them..
		  # or maybe get a service to find out ;-)
		  services => ['XPathQueryService','XUpdateService'],
	      };
	
	return bless $self, $class; 
}


1;


__END__


