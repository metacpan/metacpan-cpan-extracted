package XML::DB::Database::Xindice;
use strict;

use RPC::XML;
use RPC::XML::Client;
use XML::LibXML;
use XML::LibXML::Common;
use XML::DB::Database;

BEGIN {
	use vars qw (@ISA $DEFAULT_URL $MAX_TRANSMISSION_ATTEMPTS);
	$DEFAULT_URL = 'http://localhost:4080';
        $MAX_TRANSMISSION_ATTEMPTS = 3;
	@ISA         = qw (XML::DB::Database);
}

=head1 NAME

XML::DB::Database::Xindice - XML:DB driver for the Xindice database

=head1 SYNOPSIS

  use XML::SimpleDB::Database::Xindice;


=head1 DESCRIPTION

This is the Xindice XML-RPC driver. It is intended to be used through the XML:DB API, so that it is never called directly from user code. It implements the internal API defined in XML::DB::Database.

The methods required to implement the Database interface are documented in Database.pm; only methods unique to Xindice, and not directly required by the XML:DB API are documented here. 

=head1 BUGS

setDocument not working.

=head1 AUTHOR

	Graham Seaman
	CPAN ID: AUTHOR
	graham@opencollector.org
	http://opencollector.org/modules

=head1 COPYRIGHT

Copyright (c) 2002 Graham Seaman. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

XML::DB::Database

=head1 METHODS

=cut


=head2 new

=over

I<Usage>     : $driver = new XML::DB::Database('Xindice');

I<Purpose>   : Constructor

I<Argument>  : $self, passed from Database.pm

I<Returns>   : Exist driver, an extension of XML::DB::Database 

I<Comments>  :  Normally only called indirectly, via the DatabaseManager

=back

=cut 

sub new{
	my ($class, $self) = @_;
      	return bless $self, $class; 
}

=head2 setURI

=over

I<Usage>     : $driver->setURI

I<Purpose>   : sets the URI

I<Argument>  : URI to use

I<Returns>   : 1

I<Comments>  : This should probably be done in the constructor but is separate till DatabaseManager is properly sorted out. 

=back

=cut 

sub setURI{
	my ($self, $url) = @_;

	$self->{'location'} = $url;
	$self->{'proxy'} = new RPC::XML::Client($url)
	    or die "couldnt create proxy\n";
}

sub _transmit{
    my ($self, @params) = @_;
    if (! defined $self->{'transmit_count'}){
        $self->{'transmit_count'} = $MAX_TRANSMISSION_ATTEMPTS;
    }
    my $req = RPC::XML::request->new(@params);
    my $resp;
    eval{
	$resp = $self->{'proxy'}->send_request($req);
    };
    if ($@){
	if ($@ =~ /Collection ([\S]+)? could not be found/i){
	    $@ = "NO_SUCH_COLLECTION: $1";
	}
        delete $self->{'transmit_count'};
	die $@;
    }
    if ($resp->is_fault){
	my $error = $resp->string;
	if ($error =~ /Collection ([\S]+)? could not be found/i){
	    $error = "NO_SUCH_COLLECTION: $1";
	} else {
            $self->{'transmit_count'}--;
            return $self->transmit(@params) if $self->{'transmit_count'};
        }
        delete $self->{'transmit_count'};
	die $error;
    }
    return $resp;
}

sub createId{
    my ($self, $collectionName) = @_;

    my $resp = $self->_transmit('db.createNewOID', $collectionName);
    return $resp->value;
}

sub createCollection{
    my ($self, $parentCollection, $collectionName) = @_;
    
    my $resp = $self->_transmit('db.createCollection', $parentCollection, $collectionName);
    return 1;
}



sub dropCollection{
    my ($self, $collectionName) = @_;
    
    my $resp = $self->_transmit('db.dropCollection', $collectionName);
    return 1;
}


sub listChildCollections{
    my ($self, $collectionName) = @_;
    my $resp;
    eval{
	$resp = $self->_transmit('db.listCollections', $collectionName);
    }; 
    if ($@){
	 die "$@ Xindice::listChildCollections($collectionName)";
    }
    my $listref = $resp->value;
    return $listref;
}



sub queryCollection{
    my ($self, $collectionName, $style, $query, $namespaces ) = @_;
    
    my $resp = $self->_transmit('db.queryCollection', $collectionName, $style, $query, RPC::XML::struct->new(%{$namespaces}));
     return $resp->value;
}


 
sub getDocument{
    my ($self, $collectionName, $id) = @_;

    my $resp = $self->_transmit('db.getDocument', $collectionName, $id);    
    return $resp->value;
}
  

 
sub getDocumentCount{
    my ($self, $collectionName) = @_;

    my $resp = $self->_transmit('db.getDocumentCount', $collectionName);    
    return $resp->value;
}
 


sub insertDocument{
    my ($self, $collectionName, $content, $id) = @_;
    my $resp = $self->_transmit('db.insertDocument', $collectionName, $id, $content);    
    return $resp->value;
}



sub listDocuments{
    my ($self, $collectionName) = @_;
    my $resp = $self->_transmit('db.listDocuments', $collectionName);    
    my $listref = $resp->value;
    return $listref;
}


sub queryDocument{
    my ($self, $collectionName, $style, $query, $namespaces, $id ) = @_;
    my $resp = $self->_transmit('db.queryDocument', $collectionName, $style, $query, RPC::XML::struct->new(%{$namespaces}), $id);    
    return $resp->value;
}
  

sub removeDocument{
    my ($self, $collectionName, $id) = @_;
 
    my $resp = $self->_transmit('db.removeDocument', $collectionName, $id);   
    return 1;
}

# METHODS NEEDED FOR RESOURCESET



sub splitContents{
    my ($self, $xmldata) = @_;
    my @contents;

    my $parser = XML::LibXML->new();
    my $dom = $parser->parse_string($xmldata);
    my $elem   = $dom->getDocumentElement();
    if ( $elem->getType() == ELEMENT_NODE ) {
	if ( $elem->getName() ne 'result' ) {
	    die "failed to parse returned result";
	}
	my $resultCount = $elem->getAttribute("count");
	if ($resultCount == 0){
	    my %docco;
	    $docco{'documentId'} = undef;
	    $docco{'content'} = $xmldata;
	    push @contents, \%docco;
	    return \@contents;
	}
	my @results = $elem->getChildnodes();
	for my $result(@results){
	    my $document = XML::LibXML->createDocument( "1.0", "UTF8" );
	    my $newnode = $result->cloneNode(1);
	    my $documentId = $newnode->findvalue('@src:key');
	    $newnode->removeAttributeNS("http://xml.apache.org/xindice/Query",'col'); 
	    $newnode->removeAttributeNS("http://xml.apache.org/xindice/Query",'key');
	    $newnode->removeAttributeNS('http://www.w3.org/2000/xmlns/','src'); # this doesnt work. FIXME
	    $document->setDocumentElement($newnode);
	    my %docco;
	    $docco{'content'} = $document->toString();
	    $docco{'documentId'} = $documentId; # there's no fragment id
	    push @contents, \%docco;
       }
    }
    else{
	die "that doesn't look like XML!";
    }

 return \@contents;
} 

# methods needed for XUpdateQueryService
sub update{
    my($self, $collection, $xupdate, $namespaces) = @_;
    my $count;
    eval{
	$count = $self->queryCollection($collection, 'XUpdate', $xupdate, $namespaces);

    };
    die $@ if $@;
    return $count;
}

sub updateResource{
    my($self, $collection, $xupdate, $namespaces, $id) = @_;
    my $count;
    eval{
	$count = $self->queryDocument($collection, 'XUpdate', $xupdate, $namespaces, $id);

    };
    die $@ if $@;
    return $count;
}

=head1 ADDITIONAL METHODS

The following methods are not used directly by this XML:DB implementation.
Some are called indirectly by the interface methods, others implement features
specific to Xindice.

=head2 setDocument

=over

I<Usage>   $id = setDocument($collectionName, $content, $id )

I<Purpose> Sets a document in the collection. setDocument should be called when the document already exists in the collection.

I<Arguments>

=over 4 
  
=item * $collectionName - The name of the collection including database instance. 

=item * $content - The new Document value 

=item * $id - The id of the Document to set

=back 

I<Returns> The id of the updated Document 

I<Throws>  Exception thrown if the document cant be found.

=back

=cut

sub setDocument{
    my ($self, $collectionName, $content, $id) = @_;

    my $resp = $self->_transmit('db.setDocument', $collectionName, $id, $content);
    return $resp->value;
}
  
=head2 listIndexers

=over

I<Usage>     : $indexers = listIndexers($collectionName )

I<Purpose>   : Returns a set containing all indexers in the collection.

I<Argument>  : collectionName The name of the collection including database instance.

I<Returns>   : Arrayref of indexers in the specified collection. 

I<Throws>    : Exception thrown if the collection could not be found or any other internal error occurs.

=back

=cut

sub listIndexers{
    my ($self, $collectionName) = @_;

    my $resp = $self->_transmit('db.listIndexers', $collectionName);    
    return $resp->value;
}

 
=head2 createIndexer

=over

I<Usage>     : createIndexer($collectionName, $indexName, $pattern )

I<Purpose>   : Creates a new indexer in the specified Collection. 

I<Arguments>  : 

=over 4

=item * $collectionName - The name of the collection including database instance.

=item * $indexName - The name of the newly created indexer.

=item * $pattern - The pattern of the indexer.

=back

I<Returns>   : 1 on success

I<Throws>    : Exception thrown if the collection could not be found or any other internal error occurs.

=back

=cut

sub createIndexer{
    my ($self, $collectionName, $indexName, $pattern) = @_;
    
    my $resp = $self->_transmit('db.createIndexer', $collectionName, $indexName, $pattern);
    return 1;
}

=head2 dropIndexer

=over

I<Usage>     : dropIndexer( String collectionName, String index )

I<Purpose>   : Removes indexer in the specified Collection

I<Arguments>  : 

=over 4

=item * $collectionName - The name of the collection including database instance.

=item * $indexerName - The name of the indexer to remove.

=back

I<Returns>   : 1 on success

I<Throws>    : Exception thrown if the indexer could not be found or any other internal error occurs.

=back

=cut

sub dropIndexer{
    my ($self, $collectionName, $indexName) = @_;
    
    my $resp = $self->_transmit('db.dropIndexer', $collectionName, $indexName);
    return 1;
}

=head2 listXMLObjects

=over

I<Usage>     : @objects = listXMLObjects($collectionName)

I<Purpose>   : Lists all XML objects within the collection

I<Argument>  : $collectionName The name of the collection including database instance.

I<Returns>   : Arrayref of XML objects 

I<Throws>    : Exception thrown if any internal error occurs.

=back

=cut

sub listXMLObjects{
    my ($self, $collectionName) = @_;
    
    my $resp = $self->_transmit('db.listXMLObjects', $collectionName);
    my $listref = $resp->value;
    return $listref;
}
  
1; 
__END__


