package XML::DB::Service::XUpdateQueryService;
use XML::XUpdate::LibXML;
use XML::Normalize::LibXML qw(xml_strip_whitespace);
use XML::DB::ResourceSet;
use strict;

BEGIN {
	use vars qw (@ISA $VERSION);
	$VERSION = 0.01;
	@ISA  = qw (XML::DB::Service);
}

=head1 NAME

XML::DB::Service::XUpdateQueryService - provides XUpdate queries

=head1 SYNOPSIS

$service = $collection->getService('XUpdateQueryService', '1.0');
$service->update($xupdate);
$service->updateResource($xupdate, $documentId);

=head1 DESCRIPTION

Implements XML::DB::Service, to provide XUpdate queries of the collection it is derived from.

In principle, an xupdate should just be sent over the transport mechanism to be
dealt with by the database, if it supports XUpdate. Where a database doesnt support XUpdate natively yet, it has to be done by fetching the files, applying the update, and then writing them back.

=head1 BUGS

Updates do not return a node count as per spec (what is this useful for anyway?), since that would require interfering with the guts of XML::XUpdate::LibXML, or reimplementing it. 
 
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

=head1 PUBLIC METHODS


=cut

=head2 update

=over

I<Usage>  : $no_modified = $service->update($xupdate);

I<Purpose> : Runs xupdate against whole collection and writes result back to database

I<Arguments> : XUpdate XML string

I<Returns> : Integer (count of modified nodes)

=back

=cut

sub update{
    my ($self, $xupdate) = @_;
    my $count;
    my $collection = $self->{'collection'}->{'path'};
    my $namespaces = $self->{'namespaces'};
    my $driver = $self->{'collection'}->{'driver'};
    eval{
	$count = $driver->update($collection, $xupdate, $namespaces);
    };
    if ($@){ 
	if ($@ =~ /not supported/){
	    eval{
		$count = $self->_update($xupdate);
	    };
	    die $@ if $@;
	}
	else{
	    die $@;
	}
    }	
 #   print $count;
    return $count;
}

sub _update{
    my ($self, $xupdate) = @_;
    my $count;
    my $collection = $self->{'collection'};

    my $parser = XML::LibXML->new();
    my $update = XML::XUpdate::LibXML->new();
    my $actions = $parser->parse_string($xupdate);
    my $resources = $collection->listDocuments();
    foreach(@{$resources}){
	eval{
	    my $resource = $collection->getResource($_);
	    my $dom = $parser->parse_string($resource->getContent());
	    $update->process($dom->getDocumentElement(), $actions);
	    $resource->setContent($dom->toString);
	    $collection->storeResource($resource);
	};
	die $@ if $@;
    } 
    return $count;
}

=head2 updateResource

=over

I<Usage>  : $no_modified = $service->update($resource_name, $xupdate);

I<Purpose> : Runs xupdate against one Resource and writes result back to database

I<Arguments> : String representing resource (id or name); XUpdate XML string

I<Returns> : Integer (count of modified nodes)

=back

=cut

sub updateResource{
    my ($self, $id, $xupdate) = @_;
    my $count;
    my $collection = $self->{'collection'}->{'path'};
    my $driver = $self->{'collection'}->{'driver'};
    my $namespaces = $self->{'namespaces'};
    my $result;
    eval{
	$count = $driver->updateResource($collection, $xupdate, $namespaces, $id)
#	die "not implemented";
    };
     if ($@){ 
	if ($@ =~ /not supported/){
	    eval{
		$count = $self->_updateResource($id, $xupdate);
	    };
	    die $@ if $@;
	}
	else{
	    die $@;
	}
    }	
    return $count;
}

sub _updateResource{
    my ($self, $id, $xupdate) = @_;
    my $count;

    my $collection = $self->{'collection'};
    eval{
	my $resource = $collection->getResource($id);
 	my $parser = XML::LibXML->new();
	my $update = XML::XUpdate::LibXML->new();
	my $actions = $parser->parse_string($xupdate);
	my $dom = $parser->parse_string($resource->getContent());
	$update->process($dom->getDocumentElement(), $actions);
	$resource->setContent($dom->toString);
	$collection->storeResource($resource);
    };
    die $@ if $@; 

    return $count;
}


=head2 new

=over

I<Usage>     : Should only be called indirectly, from a Collection (see Synopsis)

I<Purpose>   : Constructor

=back

=cut 

sub new{
	my ($class, $self) = @_;
	bless $self, $class;
	return $self; 
}


1; 
__END__


