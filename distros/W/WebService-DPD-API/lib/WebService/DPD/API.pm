package WebService::DPD::API;
use strict;
use warnings;
use Carp;
use Moo;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI::Escape;
use Data::Dumper;
use JSON;
use MIME::Base64;
use namespace::clean;

# ABSTRACT: communicates with DPD API

our $VERSION = 'v0.0004';

 
=head1 NAME

WebService::DPD::API 

=head1 WARNING

This module is depreciated. It will be replaced by WebService::GeoPost::DPD, this is allow expanding the namespace to accomodate other API services provided by GeoPost.

=head1 SYNOPSIS


    $dpd = WebService::DPD::API->new(
                                        username => $username,
                                        password => $password,
                                        geoClient => "account/$customer_id",
                                        );
=cut

=head1 DESCRIPTION

This module provides a simple wrapper around DPD delivery service API. This is a work in progress and contains incomplete test code, methods are likely to be refactored, you have been warned.


=head1 METHODS

=cut


has username => (
	is => 'ro',
	required => 1,
);

has password => (
	is => 'ro',
	required => 1,
);

has url => ( is => 'ro',
			 default => sub {'https://api.dpd.co.uk'},
			);

has host => ( is => 'ro',
				lazy => 1,
			 default => sub { 
			 					my $self=shift; 
								my $url = $self->url; 
								$url =~ s/^https{0,1}.:\/\///; 
								return $url; },
			);

has ua => (
	is => 'rw',
);

has geoSession => (
	is => 'rw',
);

has geoClient => (
	is => 'ro',
	default => sub {'thirdparty/pryanet'},
);

has debug => (
	is => 'rw',
	default => 0,
);

has errstr => (
	is => 'rw',
	default => '',
);

sub BUILD 
{
	my $self = shift;
	$self->ua( LWP::UserAgent->new );
	$self->ua->agent("Perl_WebService::DPD::API/$VERSION");
	$self->ua->cookie_jar({});
}




=head2 login

Authenticates and establishes api session used by following methods

	$dpd->login;

=cut
sub login
{
	my $self = shift;
	my $result =  $self->send_request( {
										path	=> '/user/?action=login',
										type	=> 'POST',
										header	=>  {
														Authorization => 'Basic ' . encode_base64($self->username . ':' . $self->password, ''),
													},
										} );
	$self->geoSession( $result->{geoSession} );
	return $result;
}

=head2 get_country( $code )

Retrieves the country details for a provided country code and can be used to determine if a country requires a postcode or if liability is allowed etc.

	$country = $dpd->get_country( 'GB' );
	
=cut
sub get_country
{
	my ( $self, $code ) = @_;
	$self->errstr( "No country code" ) and return unless $code;
	return $self->send_request ( {
									path => '/shipping/country/' . $code,
									} );
}

=head2 get_services( \%shipping_information )

Retrieves list of services available for provided shipping information.

    my $address = {
                    countryCode     => 'GB',
                    county          => 'West Midlands',
                    locality        => 'Birmingham',
                    organisation    => 'GeoPost',
                    postcode        => 'B661BY',
                    property        => 'GeoPost UK',
                    street          => 'Roebuck Ln',
                    town            => 'Smethwick',
                    };

    my $shipping = {
                        collectionDetails   => {
                                                    address => $address,
                                                    },
                        deliveryDetails     => {
                                                    address => $address,
                                                    },
                        deliveryDirection   => 1, # 1 for outbound 2 for inbound
                        numberOfParcels     => 1,
                        totalWeight         => 5,
                        shipmentType        => 0, # 1 or 2 if a collection on delivery or swap it service is required 
                        };

    my $services = $dpd->get_services( $shipping );


=cut
sub get_services
{
	my ( $self, $shipping ) = @_;
	$self->errstr( "No shipping information" ) and return unless $shipping;
	return $self->send_request ( {
									path => '/shipping/network/?' . $self->_to_query_params($shipping),
									} );
}

=head2 get_service( geoServiceCode )

Retrieves the supported countries for a geoServiceCode

	$service = $dpd->get_service(812);

=cut
sub get_service
{
	my ( $self, $geoServiceCode ) = @_;
	$self->errstr( "No geoServiceCode" ) and return unless $geoServiceCode;
	return $self->send_request ( {
									path => "/shipping/network/$geoServiceCode/",
									} );
}

=head2 create_shipment( \%data )

Creates a shipment object

	my $shipment_data = {
							jobId => 'null',
							collectionOnDelivery =>  "false",
							invoice =>  "null",
							collectionDate =>  $date,
							consolidate =>  "false",
							consignment => [
												{
													collectionDetails => {
																			contactDetails => {
																								contactName => "Mr David Smith",
																								telephone => "0121 500 2500"
																								},
																			address => $address,
																			},
													deliveryDetails => {
																			contactDetails => {
																								contactName => "Mr David Smith",
																								telephone => "0121 500 2500"
																												},
																			notificationDetails => {
																									mobile => "07921 123456",
																									email => 'david.smith@acme.com',
																									},
																			address => {
																						organisation => "ACME Ltd",
																						property => "Miles Industrial Estate",
																						street => "42 Bridge Road",
																						locality => "",
																						town => "Birmingham",
																						county => "West Midlands",
																						postcode => "B1 1AA",
																						countryCode => "GB",
																						}
																		},
													networkCode => "1^12",
													numberOfParcels => '1',
													totalWeight => '5',
													shippingRef1 => "Catalogue Batch 1",
													shippingRef2 => "Invoice 231",
													shippingRef3 => "",
													customsValue => '0',
													deliveryInstructions => "Please deliver to industrial gate A",
													parcelDescription => "",
													liabilityValue => '0',
													liability => "false",
													parcels => [],
													consignmentNumber => "null",
													consignmentRef =>  "null",
												}
											]
						};


	$shipment = $dpd->create_shipment( $shipment_data_example );

=cut
sub create_shipment
{
	my ( $self, $data ) = @_;
	$self->errstr( "No data" ) and return unless $data;
	return $self->send_request ( {
									type => 'POST',
									path => "/shipping/shipment",
									data => $data,
									} );
}

=head2 list_countries

Provides a full list of available shipping countries

	$countries = $dpd->list_countries;

=cut

sub list_countries
{
	my $self = shift;
	return $self->send_request ( {
									path => '/shipping/country',
									} );
}

=head2 get_labels( $shipment_id, $format )

Get label for given shipment id, available in multiple formats

	$label = $dpd->get_labels( $shipment_id, 'application/pdf' );

=cut
sub get_labels
{
	my ( $self, $id, $format ) = @_;
	$self->errstr( "No shipment ID/format provided" ) and return unless ( $id and $format );
	return $self->send_request ( {
									path	=> "/shipping/shipment/$id/label/",
									header	=> { 
													Accept => $format,
												},
									raw_result => 1,
									} );

}


=head1 FUTURE METHODS

These methods are implemented as documented in the DPD API specification.  Although at the time of writing their functionality has not been publicly implemented within the API.

=cut 


=head2 request_job_id

Get a job id to group shipments

	$job_id = $dpd->request_jobid;

=cut 
sub request_jobid
{
	my ( $self ) = @_;
	return $self->send_request( {
									type	=> 'GET',
									path	=> '/shipping/job/',
									header	=> {
													Accept => 'application/json',
												}	
									} );
}

=head2  get_labels_for_job( $id, $format )

Retrieves all labels for a given job id

	$labels = $dpd->get_labels_for_job( $id, $format );

=cut
sub get_labels_for_job
{
	my ( $self, $id, $format ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	$self->errstr( "No format provided" ) and return unless $format;
	return $self->send_request( {
									path	=> "/shipping/job/$id/label",
									header	=> {
													Accept => $format,
												}
									} );
}


=head2 get_shipments( \%search_params )

Retrieves a full list of shipments meeting the search criteria and/or collection date. If no URL parameters are set the default settings brings back the first 100 shipments found.

    $shipments = $self->get_shipments( {
                                            collectionDate => $date,
                                            searchCriterea => 'foo',
                                            searchPage     => 1,
                                            searchPageSize => 20,
                                            useTemplate    => false,
                                        });
=cut
sub get_shipments
{
	my ( $self, $params ) = @_;
	my $path = '/shipping/shipment/';
	$path .= '?' . $self->_to_query_params($params) if $params;
	return $self->send_request( {
									path => $path,
									} );

}

=head2 get_shipment( $id )

Retrieves all shipment information associated with a shipment id

	$shipment = $dpd->get_shipment( $id );

=cut
sub get_shipment
{
	my ( $self, $id ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	return $self->send_request( {
									path => "/shipping/shipment/$id/",
									} );
}

=head2 get_international_invoice( $shipment_id )

Creates and returns an international invoice associated with the given shipment id.

	$invoice = $dpd->get_international_invoice( $shipment_id );

=cut
sub get_international_invoice
{
	my ( $self, $id ) = @_;
	$self->errstr( "No shipment ID provided" ) and return unless $id;
	return $self->send_request( { 
									path	=> "/shipping/shipment/$id/invoice/",
									header	=> {
													Accept => 'text/html',
												},
									raw_result => 1,
									} );
}

=head2 get_unprinted_labels( $date, $format )

Retrieves all labels that have not already been printed for a particular collection date.

	$labels = $dpd->get_unprinted_labels( $date, $format );

=cut
sub get_unprinted_labels
{
	my ( $self, $date, $format ) = @_;
	$self->errstr( "No date" ) and return unless $date;
	return $self->send_request( {
									path	=> "/shipping/shipment/_/label/?collectionDate=$date",
									header	=> {
													Accept => $format,
												}
									} );
}

=head2 delete_shipment( $id )

	Delete a shipment

	$dpd->delete_shipment( $id );

=cut
sub delete_shipment
{
	my ( $self, $id ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	return $self->send_request( {
									type	=> 'DELETE',
									path	=> "/shipping/shipment/$id/",
									} );
}

=head2 change_collection_date( $id, $date )

Update collection date for a shipment

	$dpd->change_collection_date( $id, $date );

=cut
sub change_collection_date
{
	my ( $self, $id, $date ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	$self->errstr( "No date provided" ) and return unless $date;
	return $self->send_request( {
									type	=> 'PUT',
									path	=> "/shipping/shipment/$id/?action=ChangeCollectionDate",
									data	=> {
													collectionDate => $date,
												}
									} );
}

=head2 void_shipment

Update status of shipment to void.

	$dpd->void_shipment( $id );

=cut 
sub void_shipment
{
	my ( $self, $id ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	return $self->send_request( {
									type	=> 'PUT',
									path	=> "/shipping/shipment/$id/?action=Void",
									data	=> {
													isVoided => 'true',
												},
									} );
}

=head2 create_manifest

Tag all non manifested shipments for a collection date with a new generated manifest id.

	$manifest = $dpd->create_manifest( $date );

=cut
sub create_manifest
{
	my ( $self, $date ) = @_;
	$self->errstr( "No date provided" ) and return unless $date;
	return $self->send_request( {
									type	=> 'POST',
									path	=> '/shipping/manifest/',
									data	=> {
													collectionDate => $date,
												},
									} );
}

=head2 get_manifest_by_date( $date )

Retrieves all the manifests and the core manifest information for a particular collection date.
	
	$manifests = $dpd->get_manifest_by_date( $date );

=cut
sub get_manifest_by_date
{
	my ( $self, $date ) = @_;
	return $self->send_request( {
									path	=> "/shipping/manifest/?collectionDate=$date",
									} );
}

=head2 get_manifest_by_id( $id )

Get printable manifest by its associated manifest id

	$manifest = get_manifest_by_id( $id );
=cut
sub get_manifest_by_id
{
	my ( $self, $id ) = @_;
	$self->errstr( "No id provided" ) and return unless $id;
	return $self->send_request( {
									path	=> "/shipping/manifest/$id",
									header	=> {
													Accept => 'text/html',
												},
									} );
}


=head1 INTERNAL METHODS

=cut

=head2 _to_query_params

Recursively converts hash of hashes into query string for http request

=cut
sub _to_query_params
{
	my ( $self, $data ) = @_;
	my @params;
	my $sub;
	$sub = sub {
					my ( $name, $data ) = @_;
					for ( keys %$data )
					{
						if ( ref $data->{$_} eq 'HASH' )
						{
							$sub->( "$name.$_", $data->{$_} );
						}
						else
						{
							push @params, { key => "$name.$_", value => $data->{$_} };
						}
					}
				};
	$sub->( '', $data);
	my $query;
	for ( @params )
	{
		$_->{key} =~ s/^\.//;
		$query .= $_->{key} . '='.  uri_escape( $_->{value} ) . '&';
	}
	$query =~ s/&$//;
	return $query;
}

=head2 send_request( \%args )

Constructs and sends authenticated HTTP API request

    $result = $dpd->send_request( {
                                    type    => 'POST',                    # HTTP request type defaults to GET
                                    path    => "/path/to/service",        # Path to service
                                    data    => {                          # hashref of data for POST/PUT requests, converted to JSON for sending 
                                                    key1 => 'value1',
                                                    key2 => 'value2',
                                                },
                                    content_type => 'appilcation/json',   # defaults to application/json
                                    header  => {                          # hashref of additional headers
                                                    Accept => $format,
                                                }

                                    } );

=cut
sub send_request
{
	my ( $self, $args ) = @_;
	my $type = $args->{type} || 'GET';
	my $req = HTTP::Request->new($type => $self->url . $args->{path} );
	#Required headers
	$req->header( Host => $self->host );
	$req->protocol('HTTP/1.1');
	$req->header( GEOClient =>  $self->geoClient );
	$req->header( GEOSession =>  $self->geoSession ) if $self->geoSession;
	
	#Per request overridable
	$req->content_type( $args->{content_type} || 'application/json' );
	$req->header( Accept => $args->{header}->{Accept} || 'application/json' );

	#Custom headers
	for ( keys %{ $args->{header} } )
	{
		$req->header( $_ => $args->{header}->{$_} );
	}

	if ( $args->{data} and $type =~ /^(POST|PUT)$/ )
	{
		my $content = to_json( $args->{data} );
		#hacky translation to correct representation of null and boolean values
		$content =~ s/"null"/null/gi;
		$content =~ s/"false"/false/gi;
		$content =~ s/"true"/true/gi;
		$req->content( $content );
	}

	#Send request
	warn $req->as_string if $self->debug;
	my $response = $self->ua->request($req);
	warn $response->as_string if $self->debug;
	if ( $response->code == 200 )
	{
		my $result;
		#FIXME assumes JSON
		eval{ $result = JSON->new->utf8->decode($response->content) };
		$self->errstr("Server response was invalid\n") and return if $@ and ! $args->{raw_result};
		if ( $result->{error} )
		{
			my $error = ref $result->{error} eq 'ARRAY' ? $result->{error}->[0] : $result->{error};
			my $error_type = $error->{errorType} || '';
			my $error_obj = $error->{obj} || '';
			my $error_code = $error->{errorCode} || '';
			my $error_message = $error->{errorMessage} || '';
			$self->errstr( "$error_type error : $error_obj :  $error_code : $error_message\n" );
			return;
		}
		$result->{response} = $response;
		if ( $args->{raw_result} )
		{
			$result->{data} = $response->content;
		}
		return $result->{data};
	}
	else
	{
		$self->errstr('API communication error: ' . $args->{path} . ': ' . $response->status_line . "\n\n\n\n");
		return;
	}
}

1;

=head1 SOURCE CODE

The source code for this module is held in a public git repository on Github : https://github.com/pryanet/WebService-DPD-API

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2014 Richard Newsham, Pryanet Ltd
 
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
 
=head1 BUGS AND LIMITATIONS
 
See rt.cpan.org for current bugs, if any.
 
=head1 INCOMPATIBILITIES
 
None known. 
 
=head1 DEPENDENCIES

	Carp
	Moo
	LWP::UserAgent
	LWP::Protocol::https
	HTTP::Request::Common
	URI::Escape
	Data::Dumper
	JSON
	MIME::Base64
	namespace::clean

=cut
