#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 0.98;
use Test2::Tools::Exception qw/dies lives try_ok/;
use UK::Vehicle;
use UK::Vehicle::Status;
use Scalar::Util qw(looks_like_number);
use Config::Tiny;
use DateTime;

my $ves_test_url = "https://uat.driver-vehicle-licensing.api.gov.uk/vehicle-enquiry/v1/vehicles";

SKIP: {
	skip ("active API tests; no config found in ./t/config/test_config.ini") unless -e './t/config/test_config.ini' ;
	note(" --- Running authentication tests - loading config ./t/config/test_config.ini");

	# VALIDATE CONFIGURATION FILE
	ok(my $config =  Config::Tiny->read( './t/config/test_config.ini' ) , 'Load Config defined at ./t/config/test_config.ini }' );
	ok(defined($config->{'KEYS'}->{'VES_API_KEY'}), "Config file has a VES key in it");

	my $tool;
	$tool = UK::Vehicle->new(ves_api_key => $config->{'KEYS'}->{'VES_API_KEY'}, _use_uat => 1);
	my $status;

	# Simulated 429 Too Many Requests
	ok($status = $tool->get("ER19THR"), "Get method doesn't croak when HTTP status code is 429");
	ok(defined($status), "Get method returns something when HTTP status code is 429");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 0, "Overuse returns success code 0");
	is($status->message, "429 Too Many Requests", "Overuse returns error message");
	sleep 1;

	# Simulated 400 bad request
	ok($status = $tool->get("ER19BAD"), "Get method doesn't croak when HTTP status code is 400");
	ok(defined($status), "Get method returns something when HTTP status code is 400");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 0, "Bad car returns success code 0");
	is($status->message, "400 Bad Request", "Invalid car returns error message");
	sleep 1;

	# Simulated 500 Internal Server Error
	ok($status = $tool->get("ER19ERR"), "Get method doesn't croak when HTTP status code is 500");
	ok(defined($status), "Get method returns something when HTTP status code is 500");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 0, "ISE returns success code 0");
	is($status->message, "500 Internal Server Error", "ISE returns error message");
	sleep 1;

	# Simulated 503 Service Unavailable
	ok($status = $tool->get("ER19MNT"), "Get method doesn't croak when HTTP status code is 503");
	ok(defined($status), "Get method returns something when HTTP status code is 503");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 0, "Service unavailable returns success code 0");
	is($status->message, "503 Service Unavailable", "ISE returns error message");
	sleep 1;

	# Get an unknown car
	ok($status = $tool->get("AA19AAB"), "Get method doesn't croak");
	ok(defined($status), "Get method returns something");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 0, "Valid car returns success code 0");
	is($status->message, "404 Not Found", "Valid car returns error message");
	sleep 1;
	
	# Get a car with no MoT data
	ok($status = $tool->get("AA19AAA"), "Get method doesn't croak");
	ok(defined($status), "Get method returns something");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 1, "Valid car returns success code 1");
	is($status->message, "success", "Valid car returns success message");
	sleep 1;
	
	# Check properties
	my $now = DateTime->now();
	ok(looks_like_number($status->co2Emissions), "Emissions is a number");
	ok(length($status->colour) > 2, "Colour has some text");
	is(ref($status->dateOfLastV5CIssued), "DateTime", "V5C issue date is a DateTime");
	my $v5c_date = DateTime->new(year => 2019, month => 05, day => 20);
	$status->dateOfLastV5CIssued->set_time_zone('UTC');
	is_deeply($status->dateOfLastV5CIssued, $v5c_date, "V5C issue date has correct values and time zone");
	ok(looks_like_number($status->engineCapacity), "Engine capacity is a number");
	ok(length($status->euroStatus) > 4, "Euro status has some text");
	ok(length($status->fuelType) > 2, "Fuel type has some text");
	ok(length($status->make) > 1, "Manufacturer has some text");
	is($status->manufacturer, $status->make, "Manufacturer is an alias for make");
	is_deeply($status->markedForExport, 0, "markedForExport is a literal zero");
	my $reg_month = DateTime->new(year => 2019, month => 03);
	$status->monthOfFirstRegistration->set_time_zone('UTC');
	is_deeply($status->monthOfFirstRegistration, $reg_month, "Month of registration has correct values and time zone");
	ok(length($status->motStatus) > 1, "MOT status has some text");
	is($status->registrationNumber, "AA19AAA", "Registration number is the same as the one we asked for");
	is($status->vrm, "AA19AAA", "VRM is an alias of regsitration Number"); 
	ok(looks_like_number($status->revenueWeight), "revenueWeight is a number");
	my $tax_due = DateTime->new(year => $now->year + 1, month => $now->month, day => $now->day);
	$status->taxDueDate->set_time_zone('UTC');
	is_deeply($status->taxDueDate, $tax_due, "Tax due date has correct values and time zone");
	ok(length($status->taxStatus) > 2, "taxStatus has some text");
	ok(length($status->typeApproval) > 0, "typeApproval has some text");
	ok(length($status->wheelplan) > 2, "wheelplan has some text");
	is($status->wheelPlan, $status->wheelPlan, "wheelPlan is an alias for wheelplan");
	my $year_made = DateTime->new(year => 2019, time_zone => 'Europe/London');
	is_deeply($status->yearOfManufacture, $year_made, "Year made has correct values and time zone");

	# Get a car with MoT data
	ok($status = $tool->get("AA19MOT"), "Get method doesn't croak");
	ok(defined($status), "Get method returns something");
	is(ref($status), "UK::Vehicle::Status", "Returns a UK::Vehicle::Status");
	is($status->result, 1, "Valid car returns success code 1");
	is($status->message, "success", "Valid car returns success message");
	my $mot_expiry = DateTime->new(year => $now->year + 1, month => $now->month, day => $now->day);
	$status->motExpiryDate->set_time_zone('UTC');
	is_deeply($status->motExpiryDate, $mot_expiry, "MoT expiry has correct values and time zone");
	
	sleep 1;
	


	# VRM string sanitisation
	ok($status = $tool->get("AA19 AAA"), "Get method doesn't croak when there's a space in the VRM");
	is($status->registrationNumber, "AA19AAA", "Registration number has had the space removed");
	sleep 1;
	ok($status = $tool->get("aa19aaa"), "Get method doesn't croak when lower case characters are in the VRM");
	is($status->registrationNumber, "AA19AAA", "Registration number has been upper cased");
	sleep 1;
	like(dies { $tool->get("AA19!AAA") }, qr/VRM contains an unexpected character/, "Get method does croak when there's a funny character in the VRM");
	like(dies { $tool->get("AA19 AAAA") }, qr/VRM too long/, "Get method does croak when there's the VRM is longer than permitted by law");
}

done_testing;
