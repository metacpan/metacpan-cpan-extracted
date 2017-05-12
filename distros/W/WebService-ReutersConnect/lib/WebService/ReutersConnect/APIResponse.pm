package WebService::ReutersConnect::APIResponse;
use Moose;
use HTTP::Response;
use XML::LibXML;
use Log::Log4perl;

my $LOGGER = Log::Log4perl->get_logger();

has 'http_response' => ( is => 'ro' , isa => 'HTTP::Response' , handles => qr/.*/ );

has 'xml_document' => ( is => 'ro', isa => 'XML::LibXML::Document' , lazy_build => 1 );
has 'reuters_status' => ( is => 'ro' , isa => 'Int' , lazy_build => 1 );
has 'reuters_errors' => ( is => 'ro' , isa => 'ArrayRef[HashRef]' , lazy_build => 1 );

sub _build_xml_document{
  my ($self) = @_;

  my $content = $self->http_response->content();
  return XML::LibXML->load_xml( string => $content );
}


sub _build_reuters_status{
  my ($self) = @_;

  my $doc = eval{
    $self->xml_document();
  };
  if( my $err = $@ ){
    $LOGGER->warn("Cannot build XML document: $err. Parsing: ".$self->content());
    ## This is the reuter code for general error.
    return 100;
  }

  ## Grab the status
  my ( $status ) =  $doc->documentElement()->findnodes('//status');

  unless( $status ){
    $LOGGER->debug("NO status in response. Assuming success (10)");
    return 10;
  }
  return $status->getAttribute('code') // 100;
}

sub _build_reuters_errors{
  my ($self) = @_;
  my $doc = eval{ $self->xml_document() };
  if( my $err = $@ ){
    return [ { code => 10000, error => 'Cannot parse response: '.$@ } ];
  }
  my @r = ();

  ## Ok find error nodes.
  my @error_nodes = $doc->findnodes('//status/error');
  foreach my $elt ( @error_nodes ){
    push @r, { code => $elt->getAttribute('code') // 10000,
               error => $elt->textContent() // 'No text content' };
  }
  return \@r;
}

=head1 NAME

WebService::ReutersConnect::APIResponse - A ReutersConnect API Response (decorates L<HTTP::Response>).

=cut

=head2 xml_document

Returns the L<XML::LibXML::Document> of this reuter response.

=head2 reuters_status

Returns the reuter status of this query. As per Reuters Connect doc:

 5 - Pending (only for Items)
 10 - Success
 20 - Warnings (Partial success)
 30 - Failure

=head2 reuters_errors

Returns an array ref of reuteur errors:

 [ { code => 1234 , error => 'This is error 1234' },
   { code => 5678', error => 'This is error 5678' },
   ...
 ]

=cut

=head2 is_reuters_success

Returns true if this Response is successfull in reuter's term. Meaning success or partial success.

Usage:

 unless( $this->is_reuters_success() ){
    print "Return STATUS code says: ".$this->reuters_status()."\n";
    print "Errors are: ".$this->reuters_errors_string()."\n";
 }

=cut

sub is_reuters_success{
  my ($self) = @_;
  return $self->reuters_status() == 10 || $self->reuters_status() == 20;
}

=head2 reuters_errors_string

Convenience method. Returns something reasonably nice to display in
case this request is not a success.

Usage:

  print $this->reuters_errors_string();

=cut

sub reuters_errors_string{
  my ($self) = @_;
  return join(', ', map { $_->{code}.':'.$_->{error} } @{$self->reuters_errors()} );
}

=head2 has_reuters_error

Returns true of this response has the given reuters error code.

Usage:

 if( $this->has_reuters_error(3002) ){
    ...
 }

=cut

sub has_reuters_error{
  my ($self, $error_code) = @_;
  return !!grep { $_->{code} eq $error_code } @{$self->reuters_errors()};
}

__PACKAGE__->meta->make_immutable();
1;
