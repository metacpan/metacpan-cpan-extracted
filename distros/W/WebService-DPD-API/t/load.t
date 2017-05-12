#!perl
use strict;
use warnings;

use Test::More tests => 15;

use lib 'lib';
use WebService::DPD::API;
use Data::Dumper;

my $username = 'TESTAPI';
my $password = 'APITEST';

my $time = time;
$time += 60 * 60 * 24;
my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime $time;
$year +=1900;
$mon +=1;
my $date = sprintf ("%04d-%02d-%02dT23:59:59", $year,$mon,$mday);

my $api = WebService::DPD::API->new( 
									username => $username,
									password => $password,
									);

ok( $WebService::DPD::API::VERSION, 'Loading WebService::DPD::API' );
ok( defined($api), 'Object creation' );
ok( $username eq $api->username, 'Username' ) or diag($api->errstr);
ok( $password eq $api->password, 'Password' ) or diag($api->errstr);
ok( $api->host, 'Host defined' ) or diag($api->errstr);

$api->debug(1) if ( $ENV{DEBUG} );


ok ( $api->login, 'Login' ) or diag($api->errstr);
ok ( $api->geoSession, 'GeoSession ' . $api->geoSession ) or diag($api->errstr);

my $country = $api->get_country('GB');
ok ( $country->{country}->{countryCode} eq 'GB', 'get_country' ) or diag($api->errstr);

my $address = {
				countryCode		=> 'GB',
				county			=> 'West Midlands',
				locality		=> 'Birmingham',
				organisation	=> 'GeoPost',
				postcode		=> 'B661BY',
				property		=> 'GeoPost UK',
				street			=> 'Roebuck Ln',
				town			=> 'Smethwick',
				};

my $shipping = {
					collectionDetails 	=> {
												address => $address,
												},
					deliveryDetails		=> {
												address => $address,
												},
					deliveryDirection	=> 1,
					numberOfParcels		=> 1,
					totalWeight			=> 5,
					shipmentType		=> 0,
					};

my $services = $api->get_services( $shipping);

ok( $services->[0], 'get_services') or diag($api->errstr); 

my $countries = $api->list_countries;
ok( $countries, 'list_countries' ) or diag($api->errstr);

my $service = $api->get_service(812);
ok( $service, 'get_service' ) or diag($api->errstr);
ok( $service->{network}->[0]->{networkCode}, 'get_service:networkCode' ) or diag($api->errstr);


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


my $shipment = $api->create_shipment( $shipment_data ); 
ok( $shipment, 'create_shipment' ) or diag($api->errstr);

my $label = $api->get_labels( $shipment->{shipmentId}, 'text/html' );
ok( $label, 'get_labels' ) or diag($api->errstr);


SKIP: {
	skip "Documented by DPD but not live yet", 1 unless $ENV{RUN_SKIPPED};

	my $shipment_details = $api->get_shipment( $shipment->{shipmentId} );
	ok( $shipment_details, 'get_shipment' ) or diag($api->errstr);
	
	my $shipments = $api->get_shipments;
	ok( $shipments, 'get_shipments') or diag($api->errstr);

	my $invoice = $api->get_international_invoice( $shipment->{shipmentId} );
	ok( $invoice, 'get_international_invoice' ) or diag($api->errstr);

	ok( $api->change_collection_date( $shipment->{shipmentId}, '2014-08-19' ), 'change_collection_date' ) or diag($api->errstr);
	ok( $api->void_shipment( $shipment->{shipmentId} ), 'void_shipment' ) or diag($api->errstr);
	ok( $api->delete_shipment( $shipment->{shipmentId} ), 'delete_shipment') or diag($api->errstr);
	
	my $labels = $api->get_unprinted_labels('2014-08-17', 'text/html');
	ok( $labels, 'get_unprinted_labels' ) or diag($api->errstr);
	
	my $job = $api->request_jobid;
	ok( $job, 'request_jobid' ) or diag($api->errstr);

	my $job_labels = $api->get_labels_for_job( $job->{jobId} ) or diag($api->errstr);
	ok( $job_labels, 'get_labels_for_job' ) or diag($api->errstr);

	my $manifest_date = $date;
	my $manifest = $api->create_manifest( $manifest_date );
	ok( $manifest, 'create_manifest' ) or diag($api->errstr);
	my $manifest_by_date = $api->get_manifest_by_date( $manifest_date );
	ok( $manifest_by_date, 'get_manifest_by_date' ) or diag($api->errstr);
	my $manifest_by_id = $api->get_manifest_by_id( $manifest->{manifestId} ) or diag($api->errstr);
	ok( $manifest_by_id, 'get_manifest_by_id' ) or diag($api->errstr);
}




