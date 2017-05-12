package promessaging::MRS;

use SOAP::Lite;
use XML::Simple;
use strict;

use 5.008003;

use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use promessaging::MRS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
envelope get_xml MSISDNResolve getError get_xml_request get_xml_response MRSinfo
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
envelope get_xml MSISDNResolve getError get_xml_request get_xml_response MRSinfo
);

our $VERSION = '1.01';


# location of the WSDL-description of the SOAP-service
my $wsdl = "http://www.promessaging.net/End2EndMRS.wsdl";   


# serializer class
BEGIN {

    package My::Serializer;
    @My::Serializer::ISA = 'SOAP::Serializer';

    sub envelope {
        my $self = shift;

        $self->{'xml_request'} = $self->SUPER::envelope(@_);
        return ( $self->{'xml_request'} );
    }

    sub get_xml {
        my $self = shift;

        return ( $self->{'xml_request'} );
    }
}

# constructor, no parameters needed
sub new {
    my $class = shift;
    my $self  = {};

    $self->{'error'}        = "";
    $self->{'xml_response'} = "";
    eval {
	if (
	    !(
	  $self->{'soapservice'} =
	      new SOAP::Lite->service($wsdl)->outputxml('true')
	      ->on_fault( sub { return; } )
	      )
	    )
	{
	    return (0);
	}
	$self->{'soapservice'}->serializer( My::Serializer->new );
    };
    if ($@) {
	return(0);
    }

    bless $self, $class;
}

sub MSISDNResolve {
    my $self = shift;

#    my ( $msisdn, $userid, $password, $serviceprofile, $max_retries,
#	 $interval_timeout, $interval_na ) = @_;

    my ($userid, $password, $serviceprofile, $msisdn, $max_retries, $interval_timeout, $interval_na) = @_;


    my $soapservice = $self->{'soapservice'};
    $self->{'error'} = "";

    my $retry = 0;
    my $result;
    my $interval;

    if ( !defined( $max_retries ) ) {
        $max_retries = 0;
    }
    if ( !defined( $interval_timeout ) ) {
	# default: 0 seconds because immediately retry is allowed
        $interval_timeout = 0;    
    }
    if ( !defined( $interval_na ) ) {
        # default: 300 seconds (5 minutes)
        $interval_na = 300;
    }

    while ( $retry <= $max_retries ) {
        if ( $retry > 0 ) {
            sleep $interval;
        }

        my $answer;
       
	eval {
	    $answer = $self->{'soapservice'}->MSISDNResolve( $userid,
							     $password,
							     $serviceprofile,
							     $msisdn );
	    
	    if ( substr( $answer, 0, 5 ) eq "<?xml" ) {
		$self->{'xml_response'} = $answer;
		my $xs      = new XML::Simple( suppressempty => "" );
		my $parsed  = $xs->XMLin($answer);
		my $xmlbody = $parsed->{'SOAP-ENV:Body'};
		
		if ( defined( $xmlbody->{'SOAP-ENV:Fault'} ) ) {
		    my $fault     = $xmlbody->{'SOAP-ENV:Fault'};
		    my $faultcode = $fault->{'faultcode'};
		    $result = $fault;
		    
		    if ( $faultcode == 91 ) {
			$interval = $interval_timeout;
		    }
		    elsif ( $faultcode == 99 ) {
			$interval = $interval_na;
		    }
		    else {
			last;
		    }
		    
		}
		elsif ( defined( $xmlbody->{'SOAP-ENV:MSISDNResolveResponse'} ) ) {
		    $result->{"response"} =
			$xmlbody->{'SOAP-ENV:MSISDNResolveResponse'};
		    last;
		}
		else {
		    $self->{'error'} = "no Fault or MSISDNResolveResponse in XML";
		    $interval        = $interval_na;
		    $result          = -1;
		}
	    }
	    else {
		chomp $answer;
		$self->{'error'} = $answer;
		$interval        = $interval_na;
		$result          = -2;
	    }
	};
	if ($@) {
	    $self->{'error'} = $@;
	    $interval        = $interval_na;
	    $result          = -3;	    
	}
	    
	$retry++;
    }

    return ($result);
}

sub getError {
    my $self = shift;

    return ( $self->{'error'} );
}

sub get_xml_request {
    my $self = shift;

    return ( $self->{'soapservice'}->serializer->get_xml );
}

sub get_xml_response {
    my $self = shift;

    return ( $self->{'xml_response'} );
}

# just to show basic functionality
sub MRSinfo	{

    print "\nThis shows that you installed MRS.pm succesfully!\n";

}

# Preloaded methods go here.

1;
__END__



=head1 NAME

promessaging::MRS - promessaging MRS SOAP client module

=head1 SYNOPSIS

  use promessaging::MRS;

  $mrs_object = promessaging::MRS->new();
  $result = $mrs_object->MSISDNResolve($userid,
                                       $password,
                                       $serviceprofile,
                                       $msisdn);

  $servererror = $mrs_object->getError();

=head1 MRS class methods

The following methods are provided by the promessaging::MRS class:

=over 4

=item C<new>

$mrs_object = promessaging::MRS->new();

Creates and returns a new MRS-object. Returns 0 if an error occured.

=item C<MSISDNResolve>

  $result = $mrs_object->MSISDNResolve($userid,
                                       $password,
                                       $serviceprofile,
                                       $msisdn);

  $result = $mrs_object->MSISDNResolve($userid,
                                       $password,
                                       $serviceprofile,
				       $msisdn,
                                       $retries,
                                       $interval_timeout,
                                       $interval_na);

Performs a SOAP-request.

Parameter description:
 - $userid: promessaging user-id (required)
 - $password: promessaging password (required)
 - $serviceprofile: promessaging service-profile (required)
 - $msisdn: GSM number (required)
 - $retries: number of retries if request fails (optional, default
   is zero)
 - $interval_timeout: seconds between retries if the error
   is a timeout on server-side (optional, default is zero)
 - $interval_na: seconds between retries if the service is not
   available (optional, default is 300)

MSISDNResolve returns:
 - a hash if the SOAP-request was successful:
   $return->{"response"} if subscriber is available or
   $return->{"faultcode"} and $return->{"faultstring"} if the
   server returned a fault
 - a number less than zero if a transport/server-error occured.

=item C<getError>

$errstr = $mrs_object->getError();

Returns a string which describes the transport/server-error.

=item C<get_xml_request>

$xml = $mrs_object->get_xml_request();

Returns the XML which was sent to the SOAP-server.

=item C<get_xml_response>

$xml = $mrs_object->get_xml_response();

Returns the XML which was received by the SOAP-server.


=head1 DESCRIPTION

I<MRS.pm> provides the capibility to resolve the MCC (Mobile Country Code) and MNC (Mobile Network Code)
for a given MSISDN (Mobile Station International ISDN Number, see E.164) of a mobile subscriber. Based upon
information the service also delivers detailed data about the name of the home operator, country, timezone
and other data.

Also additional information about the on/offline status of the mobile subscriber and its current location
(on country basis) can be retrieved depending on the provisioned service profile.

=head1 TECHNICAL REALISATION

The service (MSISDN Resolver Service) is built as a client/server achitecture based on the Simple Object Access
Protocol (SOAP), the client exchanges with the server XML-encapsulated data transfered via HTTP.

The MRS client submits a request to the server and in return receives the needed information or a exception if a failure
or error occurs.

The MRS server will process the query and try to lookup the subscriber via its direct SS7 access to MNOs
(Mobile Network Operator) worldwide. If the subscriber does exist the MRS server will send the data back to the
client or an exception if the subscriber is unknown or not reachable for other reasons.

=head1 ERROR CODES aka SOAP EXCEPTIONS

=over 4

=item ERROR CODE (integer) | Description (returned string) |

 Long description


=item 21 | Missing parameter ID |

Missing promessaging userid 

=item 22 | Missing parameter PW |

Missing promessaging password

=item 23 | Missing parameter MSISDN Missing |

Missing MSISDN (international format)

=item 24 | Missing parameter SP |

Missing Service Profile

=item 31 | Invalid parameter MSISDN [parameter value] |

Wrong value in parameter MSISDN

=item 41 | Not allowed to use this service |

The requesting promessaging account is not allowed to use this service

=item 42 | Unknown user |

Unknown promessaging user

=item 43 | Invalid user |

Invalid promessaging user

=item 44 | Invalid password |

Invalid promessaging password

=item 45 | Not allowed to use this service profile |

The requesting promessaging account is not allowed to use this service profile

=item 51 | Unknown subscriber |

The requested MSISDN does not exist

=item 52 | Absent subscriber |

The requested MSISDN is absent

=item 90 | Error while processing job |

An unspecified/generic error occured, End2End administrators will be informed

=item 91 | Timeout while processing job |

Timeout on HLR lookup

=item 92 | SS7 network error |

Teleservice not provisioned

=item 93 | SS7 network error |

Call bared

=item 94 | SS7 network error |

CUG-reject

=item 95 | SS7 network error |

Facility not supported

=item 96 | SS7 network error |

System failure

=item 97 | SS7 network error |

Data missing

=item 98 | SS7 network error |

Unexpected data value

=item 99 | Service not available |

The MRS service is not available at the moment

=back


=head1 COPYRIGHT

The MRS.pm module is property of End2End Denmark (E2E). Copyright End2End Denmark.
All rights reserved.

=head1 AUTHOR

B<Support & Information>

I<hotline@end2endmobile.com> for general/technical enquiries or search I<http://www.end2endmobile.com>


MRS.pm 	by Peter Friedrich

POD	by Christian Malter

=cut