package WebService::ReutersConnect::XMLDocument;
use Moose;
use XML::LibXML;
use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

has 'xml_document' => ( is => 'ro', required => 1 , handles => qr/.*/, isa => 'XML::LibXML::Document' );
has 'reuters' => ( is => 'ro', required => 1 , weak_ref => 1 , isa => 'WebService::ReutersConnect' );

has 'xml_namespaces' => ( is => 'ro', lazy_build => 1, required => 1 );
has 'xml_xpath' => ( is => 'ro', lazy_build => 1 , required => 1 );


sub _build_xml_namespaces{
  my ($self) = @_;

  my %nss = ();

  ## Find default namespace.
  my ( $default_ns ) = $self->xml_document->findnodes('/*/namespace::*[name()=\'\']');
  $nss{''} = $default_ns;

  ## Find other namespace nodes.
  my @ns_nodes = $self->xml_document->findnodes('/*/namespace::*[name()!=\'\']');
  foreach my $ns_node ( @ns_nodes ){
    $nss{$ns_node->getLocalName()} //= $ns_node;
  }

  my @namespaces = values %nss;
  return \@namespaces;
}

sub _build_xml_xpath{
  my ($self) = @_;
  my $xc = XML::LibXML::XPathContext->new( $self->xml_document() );
  foreach my $ns_node ( @{$self->xml_namespaces()} ){
    my $localname = $ns_node->getLocalName() // 'rcx';
    $LOGGER->info("Registering namespace $localname:".$ns_node->declaredURI());
    $xc->registerNs( $localname , $ns_node->declaredURI() );
  }
  return $xc;
}

sub get_html_body{
  my ($self) = @_;
  my ($body) = $self->xml_xpath->findnodes('//x:html/x:body');
  unless( wantarray ){
    return $body;
  }

  unless( $body ){ return (); }

  my @children = $body->nonBlankChildNodes();
  return @children;
}

sub get_subjects{
  my ($self)  = @_;
  my @subject_nodes = $self->xml_xpath->findnodes('//rcx:contentMeta/rcx:subject');
  my @concepts = ();
  foreach my $subject_node ( @subject_nodes ){
    if( my $concept = $self->reuters->_find_concept($subject_node->getAttribute('qcode'))){
      push @concepts  , $concept;
    }
  }
  return @concepts;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

WebService::ReutersConnect::XMLDocument - A decoration of XML::LibXML::Document with extra gizmos

=head1 SYNOPSIS

This basically acts as an L<XML::LibXML::Document> execpts it has the following extra attributes:

=head2 xml_namespaces

Returns a Array Ref list of all L<XML::LibXML::Namespace> included in this document. This is mainly for internal use.

usage:

 foreach my $ns_node ( @{$this->xml_namespaces() ){
    ## Print some stuff.
 }

=head2 xml_xpath

A ready to serve instance of <XML::LibXML::XPathContext> with the namespaces preregistered.

NOTE: The default namespace is 'rcx' (rEUTERS cONNECT xML).

Usage:

  print( $this->xml_xpath->findvalue('//rcx::headline') );
  print( $this->xml_xpath->findvalue('//rcx::description') );

=head2 get_subjects

Returns an ARRAY of L<WebService::ReutersConnect::DB::Result::Concept> representing the subjects of this reuters news document.

Usage:

  my @subjects = $this->get_subjects();
  foreach my $subject ( @subjects ){
    print $subject->name_main()."\n";
    ...
  }

=head2 get_html_body

Get the L<XML::LibXML::Element> that is the HTML Body of this rich document.

In an array context, directly returns the non blank children of the body
as an array. This is useful to directly display the body content without
outputting the 'body' element again.

Usage:

   if( my $body = $this->get_html_body() ){
     print $body->toString(1);
   }

   if( my @body_parts = $this->get_html_body() ){
     print join("\n" , map{ $_->toString(1) } @body_parts );
   }

=cut
