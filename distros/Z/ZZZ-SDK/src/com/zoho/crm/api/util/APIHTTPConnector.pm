use strict;
use warnings;
use JSON;
use src::com::zoho::crm::api::util::Constants;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;

package APIHTTPConnector;

use Moose;

our $logger = Log::Handler->get_logger("SDKLogger");

has 'request_method' =>(is => 'rw', isa => 'Str');

has 'url' =>(is => 'rw', isa => 'Str');

has 'headers' =>(is => 'rw', isa => 'HashRef');

has 'parameters' =>(is => 'rw', isa => 'HashRef');

has 'request_body' =>(is => 'rw');

has 'content_type' =>(is => 'rw');

sub new
{
	my($class) = shift;

	my $self =
	{
		headers        => undef,
		parameters     => undef,
		request_method => undef,
		url            => undef,
		request_body   => undef,
		content_type   => undef,
		file           => 0
	};

	bless $self,$class;

	return $self;
}

my $headers = HTTP::Headers->new();

sub add_header
{
	my($self, $header_name, $header_value) = @_;

	unless(defined($self->{headers}))
	{
		my %heads = ();

		$self->headers(\%heads);
	}

	$self->{headers}{$header_name} = $header_value;
}

sub add_param
{
	my($self, $param_name, $param_value) = @_;

	$self->{parameters}{$param_name} = $param_value;
}

sub is_set_content_type
{
	my($self) = shift;

	foreach(@Constants::SET_TO_CONTENT_TYPE)
	{
		my $each_url = $_;

		if(index($self->{url}, $each_url) != -1)
		{
			return 1;
		}
	}

	return 0;
}

sub fire_request
{
	my $response;

	my $converter_instance = $_[1];

	my $self = shift;

	my $lwp = LWP::UserAgent->new();

	if($self->is_set_content_type())
	{
		$self->{headers}{$Constants::CONTENT_TYPE} = $self->{content_type};
	}

	foreach my $key (keys $self->{headers})
	{
		$headers->header($key, $self->{headers}->{$key});
	}

	$APIHTTPConnector::logger->info($self->to_string());

	$self->construct_parameters();

	my $method = $self->{request_method};

	my $request = HTTP::Request->new($method, $self->{url}, $headers);

	if($method eq $Constants::REQUEST_METHOD_GET)
	{
		$response = $lwp->request($request);
	}
	elsif($method eq $Constants::REQUEST_METHOD_POST)
	{
		my $body;

		if(defined($converter_instance) && $converter_instance != '')
		{
			$body = $converter_instance->append_to_request(1, $self);
		}

		if($self->{file})
		{
			$lwp->default_headers($headers);

			$response = $lwp->post($self->{url}, Content => $body, 'Content-Type' => $self->{content_type});
		}
		else
		{
			$response = $lwp->request($request, $body);
		}
	}
	elsif($method eq $Constants::REQUEST_METHOD_PUT)
	{
		my $body;

		if(defined($converter_instance) && $converter_instance != '')
		{
			$body = $converter_instance->append_to_request($request, $self);
		}

		if($self->{file})
		{
			$lwp->default_headers($headers);

			$response = $lwp->put($self->{url}, Content => $body, 'Content-Type' => $self->{content_type});
		}
		else
		{
			$response = $lwp->request($request, $body);
		}
	}
	elsif($method eq $Constants::REQUEST_METHOD_DELETE)
	{
		$response = $lwp->request($request);
	}

	return $response;
}


sub construct_parameters
{
	my $self = shift;

	if($self->{parameters})
	{
		$self->{url} .= "?";

		foreach my $key (keys %{$self->{parameters}})
		{
			my $value = $self->{parameters}{$key};

			$self->{url} = $self->{url} . $key . "=" . $value . "&";
		}
	}
}

sub to_string
{
	my($self) = shift;

	my $JSON = JSON->new->utf8;

	my $request_headers = $self->{headers};

	my %request_headers = %{$request_headers};

	$request_headers{$Constants::AUTHORIZATION} = $Constants::CANT_DISCLOSE;

	return ("" . $self->{request_method} . ' - ' . $Constants::URL . " = " . $self->{url} . ' , ' . $Constants::HEADERS . $JSON->encode(\%request_headers) . ' , ' . $Constants::PARAMS . " = " . $JSON->encode(\%{$self->{parameters}}) . ".");


}

=head1 NAME

com::zoho::crm::api::util::APIHTTPConnector - This module is to make HTTP connections, trigger the requests and receive the response

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<fire_request>

This method makes a Zoho CRM Rest API request.

param converter : A Converter class instance to call appendToRequest method.

Returns HttpResponse class instance or null

=back

=cut

1;
