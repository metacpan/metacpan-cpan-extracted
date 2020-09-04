use strict;
use warnings;
use Scalar::Util qw(blessed);
use JSON;
use Switch;
use Data::Dumper;
use Try::Catch;
use Log::Handler;

use src::com::zoho::crm::api::util::APIHTTPConnector;
use src::com::zoho::crm::api::util::APIResponse;
use src::com::zoho::crm::api::util::JSONConverter;
use src::com::zoho::crm::api::util::XMLConverter;
use src::com::zoho::crm::api::util::Downloader;
use src::com::zoho::crm::api::util::FormDataConverter;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::crm::api::util::Constants;
use src::com::zoho::api::exception::SDKException;
use src::com::zoho::crm::api::logger::SDKLogger;
use src::com::zoho::crm::api::ParameterMap;
use src::com::zoho::crm::api::HeaderMap;

package CommonAPIHandler;

use Moose;

our $logger = Log::Handler->get_logger("SDKLogger");

use URI::Split qw(uri_split);

sub new
{
    my $class = shift;

    my $self = {
        param             => ParameterMap->new(),
        header            => HeaderMap->new(),
        api_path          => undef,
        request           => undef,
        http_method       => undef,
        module_api_name   => undef,
        content_type      => undef,
        category_method   => undef,
        mandatory_checker => undef
    };

    bless $self, $class;

    return $self;
}

sub set_content_type
{
    my($self, $content_type) = @_;

    $self->{content_type} = $content_type;
}

sub set_api_path
{
    my($self, $api_path) = @_;

    $self->{api_path} = $api_path;
}

sub set_param
{
    my($self, $param) = @_;

    $self->{param} = $param;
}

sub set_header
{
    my($self, $header) = @_;

    $self->{header} = $header;
}

sub add_param
{
    my($self,$key, $value) = @_;

    unless(defined($self->{param}))
    {
        $self->{param} = ParameterMap->new;
    }

    $self->{param}->add(Param->new($key), $value);
}

sub add_header
{
    my($self,$key, $value) = @_;

    unless(defined($self->{header}))
    {
        $self->{header} = HeaderMap->new;
    }

    $self->{header}->add(Header->new($key), $value);
}


sub set_module_api_name
{
  my($self,$module_api_name) = @_;

  $self->{module_api_name} = $module_api_name;
}

sub get_module_api_name
{
    my ($self) = shift;

    return $self->{module_api_name};
}

sub set_category_method
{
    my($self, $category_method) = @_;

    $self->{category_method} = $category_method;
}

sub get_category_method
{
    my($self) = shift;

    return $self->{category_method};
}

sub set_mandatory_checker
{
    my($self, $mandatory_checker) = @_;

    $self->{mandatory_checker} = $mandatory_checker;
}

sub get_mandatory_checker
{
    my($self) = shift;

    return $self->{mandatory_checker};
}

sub set_http_method
{
    my($self, $http_method) = @_;

    $self->{http_method} = $http_method;
}

sub get_http_method
{
    my ($self) = shift;

    return $self->{http_method};
}


sub set_request
{
    my($self,$request) = @_;

    $self->{request} = $request;
}


sub api_call
{

    my ($self, $class_name, $encode_type) = @_;

    my $connector = APIHTTPConnector->new();

    $self->set_api_url($connector);

    if(!($self->{header} eq undef) && (%{$self->{header}} ne '' || %{$self->{header}} ne undef) && keys(%{$self->{header}->{header_map}}) > 0)
    {
        $connector->headers($self->{header}->{header_map});
    }

    if(!($self->{param} eq undef) && (%{$self->{param}} ne '' || %{$self->{param}} ne undef) && keys(%{$self->{param}->{parameter_map}}) > 0)
    {
        $connector->parameters($self->{param}->{parameter_map});
    }

    Initializer::get_token()->authenticate($connector);

    # try {
    #
    # }
    # catch {
    #     my $e = shift;
    #     $CommonAPIHandler::logger->info($Constants::AUTHENTICATION_EXCEPTION . $e);
    #     # return undef;
    # };

    $connector->request_method($self->{http_method});

    my $converter = $self->get_converter_class_instance($self->{content_type});

    if(!$self->{content_type} eq undef && ($self->{http_method} eq 'POST' || $self->{http_method} eq 'PUT'))
    {
        my @class_split = split('\.', $class_name);

        my $request_class_name = "$class_split[0]";

        my $request_instance_classname = blessed($self->{request});

        # $request_instance_classname = $request_class_name . "." . $request_instance_classname;

        my $request = $converter->form_request($self->{request}, $request_instance_classname, 1);

        my %request = %{$request};

        $connector->request_body($request);

        $Converter::unique_values_hash = '';
    }

    use Config;

    $connector->{headers}{$Constants::ZOHO_SDK} = "$Config{osname}" . "/" . "$Config{osvers}" . " perl/".substr($^V, 1). ":" .$Constants::SDK_VERSION;

    my $response = $connector->fire_request($converter);

    my $response_code = $response->code();

    my %headers;

    my $return_object = undef;

    my $response_headers = $response->headers;

    my %response_headers = %{$response_headers};

    foreach my $header_key (keys %response_headers)
    {
        $headers{$header_key} = $response_headers{$header_key};
    }

    if(exists($headers{lc($Constants::CONTENT_TYPE)}))
    {
        my $mime_type = $headers{lc($Constants::CONTENT_TYPE)};

        if(index($mime_type, ";") != -1)
        {
            my @field = split /;/, $mime_type;

            $mime_type = @field[0];
        }
        my $converter_instance = $self->get_converter_class_instance("$mime_type");

        $return_object = $converter_instance->get_wrapped_response($response, $class_name);
    }
    else
    {
        $CommonAPIHandler::logger->info($response->responseCode());
    }

    return APIResponse->new(\%headers, $response_code, $return_object);
}

sub set_api_url
{
    my($self, $connector) = @_;

    my $api_path = "";

    if((index($self->{api_path}, $Constants::HTTP) != -1))
    {
        if(index($self->{api_path}, $Constants::CONTENT_API_URL) != -1)
        {
            $api_path = Initializer::get_environment->get_file_upload_url();

            try{
                my ($scheme, $auth, $path, $query, $frag) = uri_split($self->{api_path});

                $api_path = $api_path . $path;
            }
            catch{
                my $e=shift;

                $CommonAPIHandler::logger->info($Constants::INVALID_URL_ERROR . $e->to_string());

                die SDKException->new(undef, undef, undef, $e);
            }
        }
        else
        {
            if(substr($self->{api_path}, 0, 1) eq "/")
            {
                $self->{api_path} = substr($self->{api_path}, 1);
            }

            $api_path = $api_path . $self->{api_path};
        }
    }
    else
    {
        $api_path = Initializer::get_environment->get_url();

        $api_path = $api_path . $self->{api_path};
    }

    $connector->url($api_path);
}

sub get_converter_class_instance
{
    my ($self,$encode_type) = @_;

    my $converter;

    switch($encode_type)
    {
        case ["application/json", "text/plain", "text/html"]
        {
            $converter = JSONConverter->new($self)
        }
        case ["application/xml", "text/xml"]
        {
            $converter = XMLConverter->new($self)
        }
        case ["multipart/form-data"]
        {
            $converter = FormDataConverter->new($self)
        }
	    case ["application/x-download", "image/png", "image/jpeg", "application/zip", "image/gif", "text/csv", "image/tiff", "application/octet-stream"]
        {
            $converter = Downloader->new($self)
        }
    }
    return $converter;
}

=head1 NAME

com::zoho::crm::api::util::CommonAPIHandler - This class is to process the API request and its response.
                                              Construct the objects that are to be sent as parameters or in the request body with the API.
                                              The Request parameter, header and body objects are constructed here.
                                              Process the response JSON and converts it to relevant objects in the library.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates instance for CommonAPIHandler.

=item C<set_api_path>

This is a setter method to set the API request URL.

Param api_path : A String containing the API request URL.

=item C<add_param>

This method is to add an API request parameter.

Param key : A String containing the API request parameter name.

Param value : A String containing the API request parameter value.

=item C<add_header>

This method to add an API request header.

Param key :  A String containing the API request header name.

Param value : A String containing the API request header value.

=item C<set_http_method>

This is a setter method to set the HTTP method.

param http_method : A String containing http_method.

=item C<set_content_type>

This is a setter method to set an API request content type.

param content_type A String containing the API request content type.

=item C<set_request>

This is a setter method to set the API request body object.

Param request : A Object containing the API request body object.

=item C<set_module_api_name>

This is a setter method to set the Zoho CRM module API name.

Param module_api_name : A String containing the Zoho CRM module API name.

=item C<api_call>

This method is used in constructing API request and response details. To make the Zoho CRM API calls.

Param encode_type : A String containing the expected API response content type.

Param class_name : A Class containing the method return type.

=item C<getConverterClassInstance>

This method is used to get a Converter class instance.

Param encode_type : A String containing the API response content type.

Returns A Converter class instance.

=back

=cut

1;
