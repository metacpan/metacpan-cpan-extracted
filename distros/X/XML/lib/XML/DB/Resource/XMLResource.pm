package XML::DB::Resource::XMLResource;
use XML::LibXML;
use strict;

BEGIN {
	use vars qw (@ISA $VERSION);
	$VERSION = 0.01;
	@ISA  = qw (XML::DB::Resource);
}



=head1 NAME

XML::DB::Resource::XMLResource - Wrapper class for xml documents or document fragments 

=head1 SYNOPSIS

$resource = $collection->getResource($id);  
$dom = $resource->getContentAsDOM();
$resource->setContentAsDOM($dom);
$resource->getDocumentId();

=head1 DESCRIPTION

This class implements the Resource interface from the XML:DB base specification. 

=head1 BUGS

No implementation of SAX interface

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

XML::DB::Resource

=head1 PUBLIC METHODS

=cut


=head2 getContentAsDOM

=over

I<Usage>     : $r->getContentAsDOM()

I<Purpose>   : Returns the stored data as a DOM node

I<Argument>  : None

I<Returns>   : DOM node

=back

=cut

sub getContentAsDOM{
    my $self = shift;
    my $parser = XML::LibXML->new();
    my $dom = $parser->parse_string($self->{'content'});
    return $dom;
}

=head2 setContentAsDOM

=over

I<Usage>     : $r->setContentAsDOM($dom)

I<Purpose>   : Stores the DOM node

I<Argument>  : DOM node

I<Returns>   : undef

=back

=cut

sub setContentAsDOM{
    my ($self, $node) = @_;
    $self->{'content'} = $node->toString();
    return undef;
}

=head2 getContentAsSAX

=over

I<Usage>     : $saxHandler = $r->getContentAsSAX()

I<Purpose>   : Returns a SAX handler for the stored data 

I<Argument>  : None

I<Returns>   : SAX handler

=back

=cut

sub getContentAsSAX{
    my $self = shift;
    die "getContentAsSAX not yet implemented";
}

=head2 setContentAsSAX

=over

I<Usage>     : $r->setContentAsSAX($saxHandler)

I<Purpose>   : Stores contents created by the SAX handler 

I<Argument>  : SAX handler

I<Returns>   : undef

=back

=cut

sub setContentAsSAX{
    my ($self, $node) = @_;
    die "setContentAsSAX not yet implemented";
}


=head2 getDocumentId

=over

I<Usage>     : $r->getDocumentId()

I<Purpose>   : Returns the unique id for the parent document to this Resource  or null if the Resource does not have a parent document. getDocumentId() is typically used with Resource  instances retrieved using a query. It enables accessing the parent document of the Resource even if the Resource is a child node of the document. If the Resource was not obtained through a query then getId() and getDocumentId() will return the same id.

I<Argument>  : None

I<Returns>   : documentId, Id or undef


=back

=cut

sub getDocumentId{
    my $self = shift;
    if (defined $self->{'documentId'}){
	return $self->{'documentId'};
    }
    else{
	return $self->getId();
    }
}

=head2 new

=over

I<Purpose>   : Constructor

I<Comments>  : The constructor should not be called directly; new Resources are created via their parent Collection, or implicitly while building a ResourceSet.

=back

=cut

sub new{
    my ($class, $self) = @_;
    if (defined $self->{'documentId'}){
	eval{
	    $self->{'content'} = $self->{'collection'}->{'driver'}->getDocument($self->{'collection'}->{'path'}, $self->{'documentId'});
	};
	if ($@){
	    if ($@ !~ /Document not found/i){
		die $@; # may just not exist, which is fine (for eXist
		# will never exist, since we don't have an id yet; for
		# Xindice it might, if the id is an existing one
	    }
	}
	
    }
    bless $self, $class;
    return $self;
}

=head1 Methods not in the XML:DB API

=head2 getContentAsHTML

=over

I<Usage>     : $r->getContentAsHTML()

I<Purpose>   : Returns the stored data with angle brackets escaped

I<Argument>  : None

I<Returns>   : HTML-viewable string

I<Comments>  : What about pretty-printing? This just adds line breaks. And what about all the other entities? And non ASCII chars? :-(

=back

=cut

sub getContentAsHTML{
    my $self = shift;
    my $html = $self->{'content'};
    $html =~ s|<([^>]+)/>|\n&lt;$1/&gt;\n|g; # <empty /> on single line
    $html =~ s|</([^>]+)>|&lt;/$1&gt;\n|g; # </entry> ends line
    $html =~ s|<([^>]+)>|&lt;$1&gt;|g;
    return "<pre>\n$html</pre>";
}



1; 

__END__


