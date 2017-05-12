package XML::DB::Database::File;
use strict;

use File::Path;
use Fcntl qw(:DEFAULT :flock);
use XML::LibXML;
use XML::LibXML::Common;
use XML::DB::Database;

BEGIN {
	use vars qw (@ISA $DEFAULT_URL);
	$DEFAULT_URL = './t/files';
	@ISA         = qw (XML::DB::Database);
}

=head1 NAME

XML::DB::File - XML:DB driver for a simple file system

=head1 SYNOPSIS

my $driver = 'File';
my $url = '/usr/local/somewhere';

eval{
    $dbm = new XML::SimpleDB::DatabaseManager();
    $dbm->registerDatabase($driver);
    $col = $dbm->getCollection("xmldb:$driver:$url/db/test");
    };

if ($@){
    die $@;
}


=head1 DESCRIPTION

This is the driver for a simple XML File system. It is intended to be used through the XML:DB API, so that it is never called directly from user code. It implements the internal API defined in XML::DB::Database.

This is not a database; it is simply a driver for flat files, with no indexing; it was created as a convenience for testing and for transferring files between a file system and a real database.

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

=cut

sub createCollection{
    my ($self, $parentCollection, $collectionName) = @_;
    
    my $location = $self->{'location'};
    my $dir = $location.$parentCollection;
    if (! (-d $dir && -w $dir)){
	die "NO_SUCH_COLLECTION: $dir in File::createCollection";
    }
    $dir .= '/'.$collectionName;
    if (-e $dir){
	if (! (-d $dir && -w $dir)){
	    die "COLLECTION_UNUSABLE: $dir in File::createCollection";
	}
	return 1; # already exists
    }
    mkdir $dir, 0755 or die "CANNOT_CREATE_COLLECTION: $dir in File::createCollection";
    
    return 1;
}

# note there's no locking of the directory for this - its unique
# on creation, only probably unique for the next second, then
# unique again after that
sub createId{
    my ($self, $collectionName) = @_;
    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    my $id = '';
    while(-e $dir.'/'.$id){
	$id = time;
	$id .= int(rand(256));
    }
    return $id;
}

sub dropCollection{
    my ($self, $collectionName) = @_;

    my $location = $self->{'location'};
    my $dir = $location.$collectionName;  
    my $count = File::Path::rmtree($dir,0,1);
    die "CANNOT_REMOVE_COLLECTION: $dir in File::dropCollection" if (!$count);
    return 1;
}


sub listChildCollections{
    my ($self, $collectionName) = @_;

    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    opendir(COLLECTION, $dir) or die "CANNOT_OPEN_COLLECTION: $dir in File::listChildCollections";
    my @list = readdir COLLECTION;
    my @dirlist;
    for my $file(@list){
        if ($file !~ /^\./ && $file ne 'CVS' && -d "$dir/$file"){
            push @dirlist, $file;
        }
    }
    return \@dirlist;
}

# this will be as slow as treacle. 
sub queryCollection{
    my ($self, $collectionName, $style, $query, $namespaces ) = @_;
    my $list = $self->listDocuments($collectionName);
    my $parser = XML::LibXML->new();
    my $result = '';
    my $total = 0;
    for my $file(@{$list}){
	my $doc = $self->getDocument($collectionName, $file);
	my @nodes;
        my $tree = $parser->parse_string($doc);
        my $root = $tree->getDocumentElement;
        @nodes = $root->findnodes($query);
	my $count = scalar(@nodes);
	if ($count > 0){
	    $total += $count;
	    foreach(@nodes){
		# need to get the id back to Resource
		$_->setNamespace('http://opencollector.org/xmldb', 'file', 0);
		$_->setAttribute('file:source', $file );
		$result .= $_->toString();
	    }
	}
    }
    if ($total == 0){
	$result = '<result count="0"/>';
    }
    else{
        $result = "<result count=\"$total\">$result</result>";
    }
    return $result;
}

# should not die even if file doesnt exist
sub getDocument{
    my ($self, $collectionName, $id) = @_;
    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    my $file = $dir.'/'.$id;
    my $content = '';
    if (open(FH, "$file")){
	# or die "FILE_ERROR: $dir/$id in File::getDocument\n$!";
	flock(FH, LOCK_SH);
	while (<FH>){
	    $content .= $_;
	}
	close FH;
    }
    return $content;
}
 
sub getDocumentCount{
    my ($self, $collectionName) = @_;

    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    opendir(COLLECTION, $dir) or die "CANNOT_OPEN_COLLECTION: $dir in File::getDocumentCount";
    my @list = readdir COLLECTION;
    my @filelist;
    for my $file(@list){
        if ($file !~ /^\./ && $file ne 'CVS' && -f "$dir/$file"){
            push @filelist, $file;
        }
    }
    return scalar(@filelist);
}
 
sub insertDocument{
    my ($self, $collectionName, $content, $id) = @_;
    my $location = $self->{'location'};
    my $dir = $location.$collectionName;

    if (!defined $id){
	$id = $self->createId();
    }
    my $file = $dir.'/'.$id;
    open(FH, ">$file") or die "VENDOR_ERROR: $dir/$id in File::insertDocument\n$!";
    flock(FH, LOCK_EX) or die "VENDOR_ERROR: $dir/$id in File::insertDocument\n$!";
    print FH $content;
    close FH;
    
    return $id;
}

sub listDocuments{
    my ($self, $collectionName) = @_;

    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    opendir(COLLECTION, $dir) or die "CANNOT_OPEN_COLLECTION: $dir in File::listDocuments";
    my @list = readdir COLLECTION;
    my @filelist;
    for my $file(@list){
        if ($file !~ /^\./ && $file ne 'CVS' && -f "$dir/$file"){
            push @filelist, $file;
        }
    }
    return \@filelist;

}

# this will be slow. We'll ignore XUpdate, as that's done in the
# XUpdateQueryService itself, by default
# also ignoring the namespaces for now
sub queryDocument{
    my ($self, $collectionName, $style, $query, $namespaces, $id ) = @_;
    my $doc = $self->getDocument($collectionName, $id);
    my ($result, @nodes);
    if ($style eq 'XPath'){
        my $parser = XML::LibXML->new();
        my $tree = $parser->parse_string($doc);
        my $root = $tree->getDocumentElement;
        @nodes = $root->findnodes($query);
    }
    my $count = scalar(@nodes);
    if ($count == 0){ 
	$result = '<result count="0"/>';
    }
    else{
	foreach(@nodes){
	    # need to get the id back to Resource
	    $_->setNamespace('http://opencollector.org/xmldb', 'file', 0);
	    $_->setAttribute('file:source', $id );
	    $result .= $_->toString();
	}
        $result = "<result xmlns:file=\"http://opencollector.org/xmldb\" file:source=\"$id\"  count=\"$count\">$result</result>";
    }
    return $result;
}

sub removeDocument{
    my ($self, $collectionName, $id) = @_;
    my $location = $self->{'location'};
    my $dir = $location.$collectionName;
    my $file = $dir.'/'.$id;
    if (! unlink $file){
	die "FILE_ERROR: File::removeDocument()";
    }
    return 1;
}

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
	    $docco{'content'} = '<noresult/>';
	    push @contents, \%docco;
	    return \@contents;
	}
	my @results = $elem->getChildnodes();
	for my $result(@results){
	    # FIXME extract the document name for XMLResource::getDocumentId
	    my $document = XML::LibXML->createDocument( "1.0", "UTF8" );
	    my $newnode = $result->cloneNode(1);

	    my $documentId = $newnode->findvalue('@file:source');
	    $newnode->removeAttributeNS("http://opencollector.org/xmldb",'file');
	    $newnode->removeAttribute('file:source');
	    $document->setDocumentElement($newnode);
	    $document->setDocumentElement($newnode);
	    my %docco;
	    $docco{'documentId'} = $documentId;
	    $docco{'content'} = $document->toString();
	    push @contents, \%docco;
       }
    }
    else{
	die "that doesn't look like XML!";
    }

 return \@contents;
} 


=head2 new

=over

I<Usage>     : $driver = new XML::DB::Database('File');

I<Purpose>   : Constructor

I<Argument>  : $self, passed from Database.pm

I<Returns>   : File driver, an extension of XML::DB::Database 

=back

=cut 

sub new{
	my ($class, $self) = @_;
      	return bless $self, $class; 
}

sub setURI{
	my ($self, $url) = @_;
	$url =~ s|^/+||;
	$self->{'location'} = $url;
}




1; 
__END__


