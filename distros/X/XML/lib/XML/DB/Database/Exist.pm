package XML::DB::Database::Exist;
use strict;
use Carp qw(confess);
use RPC::XML;
use RPC::XML::Client;
use XML::LibXML;
use XML::LibXML::Common;
use Term::ReadLine;
use MIME::Base64;
use Getopt::Long;
use XML::DB::Database;

BEGIN {
	use vars qw (@ISA $DEFAULT_URL);
	$DEFAULT_URL = 'http://localhost:8081';
	@ISA         = qw (XML::DB::Database);
}


=head1 NAME

XML::DB::Database::Exist - XML:DB driver for the eXist database

=head1 SYNOPSIS

  use XML::DB::Database::Exist;

=head1 DESCRIPTION

This is the eXist XML-RPC driver. It is intended to be used through the XML:DB API, so that it is never called directly from user code. It implements the internal API defined in XML::DB::Database

The methods required to implement the Database interface are documented in Database.pm; only methods unique to eXist, and not required by the XML:DB API are documented here. 

=head1 BUGS

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

perl(1).

=head1 PUBLIC METHODS

=cut

=head2 new

=over

I<Usage>     : $driver = new XML::DB::Database('eXist');

I<Purpose>   : Constructor

I<Argument>  : URL for XML-RPC service

I<Returns>   : Exist driver, an extension of XML::DB::Database 

I<Comments>  : Normally only called indirectly, via the DatabaseManager

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


# private method: handle all XML::RPC comms

sub _transmit{
    my ($self, @params) = @_;

    my $req = RPC::XML::request->new(@params);
    my $resp;
    eval{
	$resp = $self->{'proxy'}->send_request($req);
    };
    if ($@){
	if ($@ =~ /collection\s+.*?not found!/){
	    die "NO_SUCH_COLLECTION";
	}
	die $@; 
    }

    if (ref($resp)){
	if ($resp->is_fault){
	    if ($resp->string =~ /collection\s+.*?not found!/){
		die "NO_SUCH_COLLECTION";
	    }
	    die 'DRIVER_ERROR: '.$resp->string;
	}
    }
    return $resp;
}

# METHODS DEFINED IN DATABASE.PM

sub createId{
    my ($self, $collection) = @_;
    my $resp;
    eval{
	$resp = $self->_transmit('createId', $collection);
	};
    die $@."Exist::createId($collection)" if ($@);
    return $resp->value;
}

sub createCollection{
    my ($self, $parentCollection, $collection) = @_;
    my $path;
    if (defined $collection){
	$path = $parentCollection .'/' . $collection;
    }
    else{
	$path = '/' . $collection;
    }
    my $resp;
    eval{
	$resp = $self->_transmit('createCollection', $path );
    };
    die $@."Exist::createCollection($parentCollection,$collection)" if ($@); 
    return $resp->value;
}


sub dropCollection{
    my ($self, $collection) = @_;
    my $resp;
    eval{
	$resp = $self->_transmit('removeCollection', $collection );
    };
    die $@."Exist::dropCollection($collection)" if ($@);
    return $resp->value;
}


sub listChildCollections{
    my ($self, $name) = @_;
    my $resp;
    eval{
	$resp = $self->getCollectionDesc($name);
    };
    die $@."Exist::listChildCollections($name)" if ($@);
    return $resp->{'collections'};
}


sub queryCollection{
    my ($self, $collection, $style, $query, $namespaces) = @_;
#    my $xpath = "collection('$collection','false')$query";
    my $xpath = "collection('$collection')$query";
    my $resp;
    eval{
	$resp = $self->existQuery($xpath);
    };
    die $@."Exist::queryCollection($collection, $query)" if ($@);
    return $resp;
}

sub getDocument{
    my ($self, $name, $id) = @_;
    $name = $name . '/' . $id;
    my $doc;
    eval{
	$doc = $self->getExistDocument($name);
    };
    die $@."Exist::getDocument($name)" if ($@);
    # need to remove the exist attributes in case this is going to
    # be written back to the db...
    my $parser = XML::LibXML->new();
    my $dom = $parser->parse_string($doc);
    my $elem = $dom->getDocumentElement();
    if ( $elem->getType() == ELEMENT_NODE ) {
	$elem->removeAttributeNS("http://exist.sourceforge.net/NS/exist",'id');
	$elem->removeAttributeNS("http://exist.sourceforge.net/NS/exist",'source');
	$elem->removeAttribute('xmlns:exist'); # this doesnt work. FIXME
	return $dom->toString();
    }
    else{
	die "MALFORMED_XML: Exist::getDocument($name, $id)";
    }

}


sub getDocumentCount{
    my ($self, $name) = @_;
    my $resp;
    eval{
	$resp = $self->getCollectionDesc($name);
    };
    die $@."Exist::getDocumentCount($name)" if ($@);
    my $docs = $resp->{'documents'};
    if (ref($docs)){
	return scalar(@{$docs});
    }
    else{
	return 0;
    }
}


sub insertDocument{
    my ($self, $path, $content, $id) = @_;
    if (!defined $id){
	$id = $self->createId();
    }
    my $docName = $path . '/' . $id;
    my $resp;
    eval{
	$resp = $self->parse($content, $docName, 1);
    };
    die $@."Exist::insertDocument($path, [content], $id)" if ($@);
    return $resp;
}

sub listDocuments{
    my ($self, $name) = @_;
    my $resp;
    eval{
	$resp = $self->getCollectionDesc($name);
    };
    die $@."Exist::listDocuments($name)" if ($@);
    my @docs;
    # docs are given their whole path, but we only want the name
    for my $doc(@{$resp->{'documents'}}){ 
	$doc =~ s|^.*?/([^/]+)$|$1|;
	push @docs, $doc
    }
    return \@docs;
}    

sub queryDocument{
    my ($self, $collection, $style, $query, $namespaces, $id) = @_;
    my $xpath = "document('$collection/$id')$query";
    my $resp;
#    print "Exist::querydocument xpath=$xpath\n";
    eval{
	$resp = $self->existQuery($xpath);
    };
    die $@."Exist::queryDocument($collection, $query)" if ($@);
    return $resp;
}

sub removeDocument{
    my ($self, $path, $id) = @_;
    my $docName = $path . '/' . $id;
    my $resp;
    eval{
	$resp = $self->remove($docName);
    };
    die $@."Exist::removeDocument($path, $id)" if ($@);
    return $resp;
}

# METHODS NEEDED FOR RESOURCESET

sub splitContents{
    my ($self, $xmldata) = @_;
    my (@contents, @ids, $resultCount);

    my $parser = XML::LibXML->new();
    my $dom = $parser->parse_string($xmldata);
    my $elem   = $dom->getDocumentElement();
    if ( $elem->getType() == ELEMENT_NODE ) {
	if ( $elem->getName() ne 'exist:result' ) {
	    die "failed to parse returned result";
	}
	$resultCount = $elem->getAttribute("hitCount");
	if ($resultCount == 0){
	    my %docco;
	    $docco{'documentId'} = undef;
	    $docco{'content'} = '<noresult/>';
	    push @contents, \%docco;
	    return \@contents;
	}
	my @results = $elem->getChildnodes();
	for my $result(@results){
	    my $document = XML::LibXML->createDocument( "1.0", "UTF8" );
	    my $newnode = $result->cloneNode(1);
	    my $id = $newnode->findvalue('@exist:id');
	    $newnode->removeAttributeNS("http://exist.sourceforge.net/NS/exist",'id');
	    my $documentId = $newnode->findvalue('@exist:source');
	    $documentId =~ s|^.*?/([^/]+)$|$1|;
	    $newnode->removeAttributeNS("http://exist.sourceforge.net/NS/exist",'source');
	    $newnode->removeAttribute('xmlns:exist'); # this doesnt work. FIXME
	    $newnode->removeAttribute('exist:source');
	    $document->setDocumentElement($newnode);
	    my %docco;
	    $docco{'id'} = $id;
	    $docco{'documentId'} = $documentId;
	    $docco{'content'} = $document->toString();
	    push @contents, \%docco;
       }
    }
    else{
	die "MALFORMED_XML: Exist::splitContents()";
    }

return \@contents;
} 


=head1 ADDITIONAL METHODS

The following methods are not used directly by this XML:DB implementation.
Some are called indirectly by the interface methods, others implement features
specific to eXist.

=head2 getExistDocument

=over

I<Usage>     : $doc = getExistDocument($name, $encoding, $prettyPrint, $xsl )

I<Purpose>   : retrieve document by name. XML content is indented if prettyPrint is set to >=0. Use supplied encoding for output. This method is provided to retrieve a document with encodings other than UTF-8. Since the data is handled as binary data, character encodings are preserved. byte-array values are automatically BASE64-encoded by the XMLRPC library.

I<Arguments>  : 

=over 4

=item * $name - the documents name.

=item * $encoding - optional (UTF8 by default)

=item * $prettyPrint - pretty print XML if >0 (optional, 0 by default)

=item * $xsl (optional)

=back

<Returns>   : xml string
 
I<Throws>   : Exception

=back

=cut

sub getExistDocument{
    my ($self, $name, $encoding, $prettyPrint, $xsl) = @_;
    if (!defined $encoding){
	# $encoding = 'UTF-8';
	$encoding = 'ISO-8859-1';
    }
    if (!defined $prettyPrint){
	$prettyPrint = 0;
    }
    # were ignoring any xsl for now
    my $resp = $self->_transmit('getDocument', $name, $encoding, RPC::XML::int->new($prettyPrint) );
    return $resp->value; 
}

=head2 hasDocument

=over

I<Usage>     : if (hasDocument($name)){.... 

I<Purpose>   : Does a document called $name exist in the repository? 

I<Argument>  : $name - string identifying document

I<Returns>   : True/false 

I<Throws>    : Exception

=back

=cut

sub hasDocument{
    my ($self, $name) = @_;

    my $resp = $self->_transmit('hasDocument', $name);
    return $resp->value;
}

=head2 getDocumentListing

=over

I<Usage>     : $docList = getDocumentListing($collection)

I<Purpose>   : get a list of all documents contained in the repository, or in the collection if $collection is defined

I<Argument>  : $collection - collection to list (may be undef)

I<Returns>   : Lists of documents as a struct consisting of: array of all document names in collection; array of all subcolection names; name of collection.  

I<Throws>    : Exception

I<Comment> : Actual behaviour doesnt match spec (above) - returns simple arrayref (maybe containing a flattened version of above structure?).

=back

=cut 

sub getDocumentListing{
    my ($self, $name) = @_;

    my $resp = $self->_transmit('getDocumentListing', $name);
    return $resp->value;
}

=head2 retrieve

=over

I<Usage>     : $xml = retrieve($doc, $id, $prettyPrint, $encoding)

I<Purpose>   : retrieve a single node from a document.

I<Arguments>  : 

=over 4

=item * $id - internal id of node

=item * $noResults - number of results to return

=item * $prettyPrint - pretty print XML if >0 (default 0)

=item * $encoding - default UTF8

=back

I<Returns>   : Base-64 encoded xml

I<Throws>    : Exception

=back

=cut

sub retrieve{
  my ($self, $resultId, $noResults, $prettyPrint, $encoding) = @_;
  if (!defined $prettyPrint){
      $prettyPrint = 0;
  }
  if (!defined $encoding){
      $encoding = 'UTF-8';
  }
  my $resp = $self->_transmit('retrieve', RPC::XML::int->new($resultId), RPC::XML::int->new(1), RPC::XML::int->new($prettyPrint), $encoding );
  return $resp->value;
}
 

=head2 executeQuery

=over

I<Usage>     : $reference = executeQuery($xpath)

I<Purpose>   : Execute XPath query and return a reference to the result set.

I<Argument>  : $xpath - the query

I<Returns>   : The returned reference may be used later to get a summary of results or retrieve the actual hits. 

I<Throws>    : Exception

=back

=cut

sub executeQuery {
  my($self, $XPath) = @_;
  my $resp = $self->_transmit('executeQuery', $XPath);
  return $resp->value;
}


=head2 parse

=over

I<Usage>     : if (parse($xml, $docName, $overwrite)){...

I<Purpose>   : parse an XML document and store it into the database.

I<Arguments>  : 

=over 4

=item * $xmlData - the documents XML content.

=item * $docName - identifying name for the document

=item * $overwrite - replace an existing document with the same name? (1=yes, 0=no)

=back

I<Returns> : 1 on success

I<Throws>    : Exception

=back

=cut

sub parse{
    my ($self, $xml, $docName, $overwrite) = @_;
    if (!defined $overwrite){
	$overwrite = 0;
    }
# base64 conversion automatic now????
#    my $resp = $self->_transmit('parse', RPC::XML::base64->new(iso2utf8($xml)), $docName, RPC::XML::int->new($overwrite));
    my $resp = $self->_transmit('parse', iso2utf8($xml), $docName, RPC::XML::int->new($overwrite));
    return $resp->value;
}

sub iso2utf8 {
    my $buffer = shift;
    $buffer =~ s/([\x80-\xFF])/chr(0xC0|ord($1)>>6).chr(0x80|ord($1)&0x3F)/eg;
    return $buffer;
}

=head2 remove

=over

I<Usage>     : if (remove($docName)){ ...

I<Purpose>   : remove a document from the repository.

I<Argument>  : $docName - document to remove

I<Returns>   : 1 on success  

I<Throws>    : Exception

=back

=cut

sub remove{
    my ($self, $docName) = @_;
    my $resp = $self->_transmit('remove', $docName );
    return $resp->value;
}



=head2 querySummary

=over

I<Usage>     : $struct = querySummary($xpath)

I<Purpose>   : execute XPath query and return a summary of hits per document and hits per doctype.

I<Argument>  : $xpath - query string

I<Returns>   :  This method returns a struct consisting of $queryTime -int; $hits - int; $documents - array of array: Object[][3]; doctypes - array of array: Object[][2], where documents and doctypes represent tables where each row describes one document or doctype for which hits were found. Each document entry has the following structure: docId (int), docName (string), hits (int). The doctype entry has this structure: doctypeName (string), hits (int)

I<Throws>    : Exception

=back

=cut

sub querySummary{
  my ($self, $resultId) = @_;
  my $resp = $self->_transmit('querySummary', RPC::XML::int->new($resultId) );
  return $resp->value;
}


=head2 getHits

=over

I<Usage>     : $hitcount = getHits($resultId) 
I<Purpose>   : Get the number of hits in the result set identified by it\'s result-set-id.
I<Argument>  : $resultId
I<Returns>   : Number of hits 
I<Throws>    : Exception

=back

=cut

sub getHits{
  my ($self, $resultId) = @_;
  my $resp = $self->_transmit('getHits', RPC::XML::int->new($resultId) );
  return $resp->value;
}



=head2 existQuery

=over

I<Usage>     : $xml = existQuery($xpath, $howmany, $start, $encoding, $prettyPrint)

I<Purpose>   : execute XPath query and return $howmany nodes from the result set, starting at position $start.

I<Arguments>  : 

=over 4

=item * $xpath - the XPath query to execute. This is in the format I<document(*|list_of_paths)> or I<collection(collectionName, true|false)>. See eXist documentation on xpath extensions.

=item * $howmany - maximum number of results to return (default 999).

=item * $start - item in the result set to start with.

=item * $encoding - the character encoding to use (default UTF8).

=item * $prettyPrint - pretty print XML if >0 (default 0)

=back

I<Returns>   : string of nodes selected 

I<Throws>    : Exception

=back

=cut

sub existQuery{
  my ($self, $XPath, $howmany, $start, $encoding, $prettyPrint) = @_;
  if (!defined $howmany){
      $howmany = 9999; # = infinity ;-)  
  }
  if (!defined $start){
      $start = 1;
  }
  if (!defined $encoding){
      $encoding = 'UTF-8';
     # $encoding =  'ISO-8859-1';
  }
  if (!defined $prettyPrint){
      $prettyPrint = 0;
  }
  $XPath = iso2utf8($XPath);
  my $resp = $self->_transmit('query', $XPath, $encoding, RPC::XML::int->new($howmany), RPC::XML::int->new($start), RPC::XML::int->new($prettyPrint));
  # return decode_base64($resp->value);
  return $resp->value;
}


=head2 getCollectionDesc

=over

I<Usage>     : $desc = getCollectionDesc($collection)

I<Purpose>   : describe a collection

I<Argument>  : $collection - name of collection

I<Returns>   :  This method will return a hashref with the following fields:
I<documents> - array of all document names contained in this collection; I<collections> - an array containing the names of all subcollections in this collection; I<name> - the collections name

I<Throws>    : Exception

=back

=cut

sub getCollectionDesc{
  my ($self, $collection) = @_;
  my $resp = $self->_transmit('getCollectionDesc', $collection );
  return $resp->value;
}





1; 

__END__


