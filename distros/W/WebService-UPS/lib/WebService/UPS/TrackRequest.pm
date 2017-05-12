#===============================================================================
#         FILE:  WebService::UPS::TrackRequest.pm
#  DESCRIPTION:  OO Module to track UPS packages using the XML UPS API. 
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================

our      $VERSION =  '0.1';
package WebService::UPS::TrackRequest;
use Mouse;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use WebService::UPS::TrackedPackage;

has 'License' => ( is => 'rw' );
has 'Username' => ( is => 'rw' );
has 'Password' => ( is => 'rw' );
has 'TrackingNumber' => ( is => 'rw' );
has 'debug' => ( is => 'rw' );
has 'URL' => ( is => 'rw', 
			   default => 'https://wwwcie.ups.com/ups.app/xml/Track');
has 'Description' => ( is => 'rw', 
			   default => 'A Package');


sub requestTrack {
	my $self = shift;
	my $_ups_xml_req = "
        <?xml version=\"1.0\" ?>
        <AccessRequest xml:lang='en-US'>
            <AccessLicenseNumber>${\$self->License}</AccessLicenseNumber>
            <UserId>${\$self->Username}</UserId>
            <Password>${\$self->Password}</Password>
        </AccessRequest>
        <?xml version=\"1.0\" ?>
        <TrackRequest>
            <Request>
                <TransactionReference>
                    <CustomerContext>${\$self->Description}</CustomerContext>
                </TransactionReference>
                <RequestAction>Track</RequestAction>
                <RequestOption>activity</RequestOption>
            </Request>
         <TrackingNumber>${\$self->TrackingNumber}</TrackingNumber>
         </TrackRequest>
        ";
	#print $self->PackageName;
    if (defined( $self->debug) ) { print $_ups_xml_req, "\n"; }
    my $userAgent = LWP::UserAgent->new(agent => 'perl post');
    my $response = $userAgent->request(POST $self->URL, Content_Type => 'text/xml',
                                                     Content => $_ups_xml_req);
    if (defined( $self->debug) ) { print $response->decoded_content, "\n"; }
    print $response->error_as_HTML unless $response->is_success;
    my $xml = new XML::Simple;
    my $processedXML = $xml->XMLin( $response->decoded_content);
	#print Dumper($processedXML);
    my $object = WebService::UPS::TrackedPackage->new();
    $object->_returned_xml($processedXML);
	return $object;
}

1;


=head1 NAME

WebService::UPS::TrackRequest - Generate a Request for Tracking Information

=head1 SYNOPSIS

	my $Package = WebService::UPS::TrackRequest->new;
	$Package->Username('kbrandt');
	$Package->Password('topsecrent');
	$Package->License('8C3D7EE8FZZZZZ4');
	$Package->TrackingNumber('1ZA45Y5111111111');
	print $Package->Username();
	my $trackedpackage = $Package->requestTrack();

=head1 License

	You will need to get a UPS Online Tools License and Account to use this module: http://www.ups.com/e_comm_access/gettools_index?loc=en_US

=head1 Methods

=head2 new()

	$package = WebService::UPS::TrackRequest->new( Username => 'kbrandt');

The constructor method that creates a new Request Object.  

=over 1

=item License 
	
You will need to register with UPS to get a developer key and then a License to access the XML Service

=item Username

Username for your UPS account

=item Password

Password for your UPS account

=item TrackingNumber

The Tracking number of your package

=item debug
	
Set this to something to make a lot of stuff appear

=item URL
	
The URL the request is set to, you shouldn't have to Touch this

=item Description

Optional, a human readable name for your package. Defaults to 'A Package'

=back


=head2 requestTrack()

	my $trackedPackage = $package->requestTrack();

Sumbits the request to UPS and returns a TrackedPackage Object

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut

