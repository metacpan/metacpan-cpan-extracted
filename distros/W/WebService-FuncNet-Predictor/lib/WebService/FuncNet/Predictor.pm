package WebService::FuncNet::Predictor;

=head1 NAME

WebService::FuncNet::Predictor - Interface to the CATH FuncNet webservice

=head1 SYNOPSIS

    use WebService::FuncNet::Predictor;

    $ws = WebService::FuncNet::Predictor->new(
                    wsdl    => 'http://funcnet.eu/soap/Geco.wsdl',
                    port    => 'GecoPort',
                    binding => 'GecoBinding',
                    service => 'GecoService',
                 );
    
    @proteins1 = qw( A3EXL0 Q8NFN7 O75865 );
    @proteins2 = qw( Q5SR05 Q9H8H3 P22676 );
    
    $response  = $ws->score_pairwise_relations( \@proteins1, \@protein2 );

    foreach $result ( @{ $response->results } ) {
        print join( ", ",
                $result->protein_1,      # Q9H8H3
                $result->protein_2,      # O75865
                $result->p_value,        # 0.445814
                $result->raw_score       # 0
            ), "\n";
    }

This module provides a simple API to the FuncNet predictor services and the documentation
provided here refers to the usage and implementation of the API rather than the details
of the actual FuncNet WebServices. For more information on FuncNet, it is best to visit
the project homepage at:

   http://funcnet.eu

=cut

use Moose;
use Moose::Util::TypeConstraints;

use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Schema;

use WebService::FuncNet::Predictor::Logger;
use WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations;

use Carp;
use URI;
use URI::Heuristic;
use URI::file;
use LWP::UserAgent;
use File::Temp qw( tempfile );
use Readonly;
use Data::Dumper;

our $VERSION = "0.11";

#Readonly my $WSDL_HOST       => 'http://bsmlx47:8080';
Readonly my $WSDL_HOST       => 'http://funcnet.eu';
Readonly my $WSDL_REMOTE_URL => $WSDL_HOST . '/soap/Geco.wsdl';
Readonly my $FUNCNET_NS      => '{http://funcnet.eu/FuncNet_1_0/}';

with 'WebService::FuncNet::Predictor::Logable';

my $logger = get_logger();

subtype 'WebService::FuncNet::Predictor::WSDL'
    => as 'Object'
    => where { $_->isa( 'XML::Compile::WSDL11' ) };

subtype 'Uri'
    => as 'Object'
    => where { $_->isa( 'URI' ) };

coerce 'WebService::FuncNet::Predictor::WSDL'
    => from 'Str|Uri'
        => via { wsdl_from_uri( $_ ) };

=head1 ACCESSORS

=head2 wsdl

Provides access to the underlying XML::Compile::WSDL11 object used to communicate with the CATH FuncNet WebService. This can be coerced from the URI of a WSDL either as 'uri' or URI->new( 'uri' ).

By default this is created from the URL:

  http://funcnet.eu/soap/Geco.wsdl

but any FuncNet predictor URL can be used here; see http://funcnet.eu/wsdls/

Coercions:

  $self->wsdl( 'uri' )
  $self->wsdl( URI->('uri') )
  $self->wsdl( XML::Compile::WSDL11->new() )

=cut

has 'wsdl' => (
    is => 'rw',
    isa => 'WebService::FuncNet::Predictor::WSDL',
    default => sub { wsdl_from_uri( $WSDL_REMOTE_URL ) },
    coerce => 1,
);

=head2 ns_base

Read-only access to the namespace string, e.g.

  http://funcnet.eu/FuncNet_1_0/

=cut

has 'ns_base' => (
    is => 'ro',
    isa => 'Str',
    default => $FUNCNET_NS,
);

=head2 port

Read-only access to the port string, e.g.

    GecoPort

=cut

has port => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    predicate   => 'has_port',
);

=head2 binding

Read-only access to the binding string, e.g.

    GecoBinding

=cut

has binding => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    predicate   => 'has_binding',
);

=head2 service

Read-only access to the service string, e.g.

    GecoService

=cut

has service => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    predicate   => 'has_service',
);


=head1 OPERATIONS

=head2 score_pairwise_relations( \@proteins1, \@proteins2 )

Provides a pairwise comparison of the relationships between two sets of proteins.
  
  $response = $ws->score_pairwise_relations( [ 'A3EXL0', 'Q8NFN7' ], [ 'Q5SR05', 'Q9H8H3' ] )

See L<WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations>

=head3 PARAMS

=over 8

=item \@proteins

ARRAY ref containing list of protein identifiers

=back

=head3 RETURNS

=over 8

=item WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response

=back

=cut

sub score_pairwise_relations {
    my ( $self, $proteins1_ref, $proteins2_ref ) = @_;

    my $op = WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations->new(
            root        => $self,
            service     => $self->service,
            port        => $self->port,
            binding     => $self->binding,
        );
    
    return $op->run( $proteins1_ref, $proteins2_ref );
}


=head1 CLASS METHODS

These are used to help create the object and aren't really intended for 
public consumption. I'm including them in the docs but I'm not exporting
them or promising that they won't change in the future.

=head2 wsdl_from_uri( $wsdl_uri )

Class method that downloads a WSDL from a remote URI then creates and returns a XML::Compile::WSDL11 object

=head3 PARAMS

=over 8

=item $wsdl_uri

String or URI object pointing to the location of the external FuncNet WSDL

=back

=head3 RETURNS

=over 8

=item XML::Compile::WSDL11

=back

=cut

sub wsdl_from_uri {
    my $uri = shift;
    
    # coerce Str to URI
    if ( !blessed $uri ) {
        $uri = new URI( $uri )
            or die "couldn't create URI from $uri";
    }
    
    # coerce external URI::http to local tmp URI::file
    if ( $uri->isa( 'URI::http' ) ) {
        $logger->debug( "coercing URI::http to URI::file ($uri)" );
        my $filename_wsdl_tmp = download_wsdl_to_tmp_file( $uri )
            or $logger->error( "couldn't download WSDL to tmp file" );
        
        $uri = new URI::file( $filename_wsdl_tmp )
            or $logger->error( "couldn't create URI::file from file '$filename_wsdl_tmp'" );
    }
    
    # deal with local
    if ( $uri->isa( 'URI::file' ) ) {
        $logger->debug( "coercing URI::file to XML::Compile ($uri)" );
        return wsdl_from_filename( $uri->file );
    }
    else {
        $logger->error( "couldn't understand URI '". blessed($uri) ."'" );
    }
    
    return;
}

=head2 wsdl_from_filename( $wsdl_filename )

Class method that creates and returns a XML::Compile::WSDL11 object from a local file

=head3 PARAMS

=over 8

=item $wsdl_filename

Filename of the WSDL

=back

=head3 RETURNS

=over 8

=item XML::Compile::WSDL11

=back

=cut

sub wsdl_from_filename {
    my $wsdl_filename = shift;
    
    $logger->debug( "creating new XML::Compile from $wsdl_filename" );
    my $wsdl        = XML::Compile::WSDL11->new( $wsdl_filename )
        or $logger->error( "couldn't create XML::Compile::WSDL11 object from filename $wsdl_filename" );
    
    return $wsdl;
}


=head2 download_wsdl_to_tmp_file( $wsdl_uri )

Class method that downloads an external WSDL and saves the content in a temporary file.

=head3 PARAMS

=over 8

=item $wsdl_uri

String or URI object pointing to the location of the external FuncNet WSDL

=back

=head3 RETURNS

=over 8

=item filename

temporary file containing the WSDL content

=back


=cut

sub download_wsdl_to_tmp_file {
    my $uri = shift;
    
    $logger->info( "downloading WSDL $uri to tmp file" );
    
    my $agent   = LWP::UserAgent->new;
    my $request = HTTP::Request->new( POST => $uri );
    my $result  = $agent->request( $request );
    my ( $tmp_fh, $tmp_filename ) = tempfile();
    
    if ($result->is_success) {
        #$logger->debug( "wsdl: ".Dumper( $result ) );
        
        print $tmp_fh $result->content
            or croak "couldn't write WSDL to temp file '$tmp_filename': $!";
        
        return $tmp_filename;
    }
    else {
        croak "couldn't get WSDL from URI '$uri' : ".$result->status_line;
    }
}

1; # Magic true value required at end of module
__END__

=head1 DESCRIPTION

The XML::Compile::WSDL11 object requires a copy of the WSDL on the local filesystem. If the object is initialised as

  WebServices::FuncNet::Predictor->new( wsdl => "uri" )               # default
  WebServices::FuncNet::Predictor->new( wsdl => URI->new( "uri" ) )

then the process of coercing the string or URI to XML::Compile::WSDL11 object will involve downloading the WSDL to a temporary file. It would be nice it this had the option of being cached.

=head1 TODO

- Manage local cache of WSDL to avoid unneccessary downloading at startup

- Add more tests (especially failing test)

- Wrap around LWP and XML::Compile exceptions

=head1 DEPENDENCIES

Moose, XML::Compile::WSDL11, URI, LWP, File::Temp, Readonly

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-cath-funcnet@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Ian Sillitoe  C<< <sillitoe@biochem.ucl.ac.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe C<< <sillitoe@biochem.ucl.ac.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 REVISION INFO

  Revision:      $Rev: 141 $
  Last editor:   $Author: isillitoe $
  Last updated:  $Date: 2010-05-26 14:11:41 +0100 (Wed, 26 May 2010) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
