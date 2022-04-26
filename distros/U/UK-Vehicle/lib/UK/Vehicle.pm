package UK::Vehicle;

use 5.030000;
use strict;
use warnings;
use UK::Vehicle::Status;
use LWP::UserAgent;
use subs 'timeout';
use Class::Tiny qw(ves_api_key _ua timeout _url),
{
	_uat_url => "https://uat.driver-vehicle-licensing.api.gov.uk/vehicle-enquiry",
	_prod_url =>  "https://driver-vehicle-licensing.api.gov.uk/vehicle-enquiry",
	_use_uat => 0
};
use Carp;
use JSON;
use Try::Tiny;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.4';

sub BUILD
{	
	my ($self, $args) = @_;
	
	$self->_ua(LWP::UserAgent->new);
	$self->_ua->timeout(10);
	$self->_ua->env_proxy;
	
	croak "parameter 'ves_api_key' must be supplied to new" unless $self->ves_api_key;
	croak "parameter 'ves_api_key' should be 40 characters long" unless length($self->ves_api_key) == 40;
	croak "parameter 'ves_api_key' has invalid characters" unless $self->ves_api_key =~ /([a-z]|[A-Z]|[0-9]){40}/;			# TODO make more complicated
	if(defined($args->{'timeout'}))
	{
		croak "Timeout value must be a number in seconds" unless looks_like_number($args->{'timeout'});
		$self->timeout($args->{'timeout'});
	}
	if($args->{'_use_uat'})
	{
		$self->_url($self->_uat_url);
	}
	else
	{
		$self->_url($self->_prod_url);
	}
}

sub get
{
	my $self = shift;
	my $vrm = shift;
	
	# Input sanitisation
	$vrm = $self->removeWhitespace($vrm);
	$vrm = uc($vrm);
	croak "VRM contains an unexpected character" if $vrm !~ /^([A-Z]|[0-9]|\s){1,}$/;
	croak "VRM too long" if length($vrm) > 7;

	my $msg_json = "{\"registrationNumber\": \"$vrm\"}";
	my $req = HTTP::Request->new('POST', $self->_url."/v1/vehicles");
	$req->header('Content-Type' => 'application/json');
	$req->header('Accept' => 'application/json');
	$req->header('x-api-key' => $self->ves_api_key);
	$req->content($msg_json);
	my $response = $self->_ua->request($req);
	my $content = $response->decoded_content();
	my $json;
	try
	{
		$json = decode_json($content);
	};
	my $message = $response->code." ".$response->message;
	if($response->is_error)
	{
		$json->{'result'} = 0;
		if($response->code != 429)
		{	# For most errors the HTTP response contains everything we need to know
			$json->{'message'} = $message;
		}
		else
		{	# But for 429 the message is in the body
			$json->{'message'} = $response->code." ".$json->{'message'};
		}
	}
	else
	{
		$json->{'result'} = 1;
		$json->{'message'} = "success";
	}
	
	return UK::Vehicle::Status->new($json);
}

sub timeout($)
{
	my $self = shift;
	my $arg = shift;
    if ($arg) {
		$self->_ua->timeout($arg);
    }
	return $self->_ua->timeout;
}

sub removeWhitespace($)
{ 
	my $self = shift;
	my $s = shift; 
	
	$s =~ s/\s+//g; 

	return $s;
}

1;
__END__

=head1 NAME

UK::Vehicle - Perl module to query the UK's Vehicle Enquiry Service API

=head1 SYNOPSIS

	use UK::Vehicle;
	my $tool  = new UK::Vehicle:(ves_api_key => '<your-api-key>');
	my $status = $tool->get('<vehicle-vrm>');
	$status->result; 	# 1 for success, 0 for failure
	$status->message;	# 'success' or an error message
	$status->is_mot_valid();
	$status->is_vehicle_taxed();
	etc..

=head1 DESCRIPTION

This module helps you query the Vehicle Enquiry Service API provided by 
the UK's DVLA. In order to use it you must have an API key, which you 
can apply for L<here|https://register-for-ves.driver-vehicle-licensing.api.gov.uk/>

You will likely need a decent reason to have an API key. It takes days 
to get one so you may want to apply now. 

=head2 EXPORTS

None.

=head1 CONSTRUCTORS

=over 3

=item new(ves_api_key => value)

=item new(ves_api_key => value, timeout => integer)

Create a new instance of this class, passing in the API key you wish to 
use. This argument is mandatory. Failure to set it upon creation will 
result in the method croaking.

Optionally also set the connect timeout in seconds. Default value is 10.  

=back

=head1 METHODS

=over 3

=item get(string)

   my $status = $tool->get("ZZ99ABC");
   $status->result;  # 1 if success, 0 if not
   $status->message; # "success" if result was 1, error message if not
   $status->make; # "ROVER" etc.

Query the API for the publicly-available information about a vehicle. 
Returns a L<UK::Vehicle::Status>, which has accessor methods for each of
the properties returned by the VES API. For more information, see 
L<UK::Vehicle::Status>.
   
Any spaces in the VRM you provide will be automatically removed. Lower
 case characters will be changed to upper case. If the
 VRM you provide contains weird characters, you will get 0 back and an
 appropriate message. Permitted characters are 0-9, a-z, A-Z.   

=back

=head1 BUGS AND REQUESTS

Please report to L<the GitHub repository|https://github.com/realflash/perl-uk-vehicle>.

=head1 AUTHOR

Ian Gibbs, E<lt>igibbs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ian Gibbs

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU GPL version 3.

=cut
