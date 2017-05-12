package WWW::EFA::HeaderFactory;
use Moose;
use WWW::EFA::ResultHeader;
use Carp;

=head1 NAME

WWW::EFA::HeaderFactory - A (very small) Factory for creating L<WWW::EFA::ResultHeader> objects.

=head1 VERSION

    Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  my $factory = WWW::EFA::HeaderFactory->new();

=head1 METHODS

=head2 header_from_result

Returns a L<WWW::EFA::ResultHeader> object

  my $location = $factory->header_from_result( $doc );

Expects an XML::LibXML::Element of XML with this as its root element:

  
<itdRequest version="9.16.27.42" language="de" lengthUnit="METER" 
    sessionID="MVV1_4147296033" client="libwww-perl/6.03" 
    clientIP="192.168.0.190" serverID="MVV1_" virtDir="mobile" 
    now="2011-11-10T15:16:22" nowWD="5">
  ...
</itdRequest>

=cut
sub header_from_result {
    my $self = shift;
    my $elem = shift;

    my( $req_elem ) = $elem->findnodes( '/itdRequest' );
    if( not $req_elem ){
        croak( "Could not find itdRequest element" );
    }

    my $header = WWW::EFA::ResultHeader->new(
        version     => $req_elem->getAttribute( 'version' ),
        language    => $req_elem->getAttribute( 'language' ),
        server_time => Class::Date->new( $req_elem->getAttribute( 'now' ) ),
        server_id   => $req_elem->getAttribute( 'serverID' ),
        length_unit => $req_elem->getAttribute( 'lengthUnit' ),
        session_id  => $req_elem->getAttribute( 'sessionID' ),
        );
    return $header;
}

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

