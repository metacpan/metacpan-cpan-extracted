=begin comment

Fastly API

Via the Fastly API you can perform any of the operations that are possible within the management console,  including creating services, domains, and backends, configuring rules or uploading your own application code, as well as account operations such as user administration and billing reports. The API is organized into collections of endpoints that allow manipulation of objects related to Fastly services and accounts. For the most accurate and up-to-date API reference content, visit our [Developer Hub](https://www.fastly.com/documentation/reference/api/) 

The version of the API Spec document: 1.0.0
Contact: oss@fastly.com

=end comment

=cut

#
# NOTE: This class is auto generated.
# Do not edit the class manually.
#
package WebService::Fastly::LoggingElasticsearchApi;

require 5.6.0;
use strict;
use warnings;
use utf8;
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);

use WebService::Fastly::ApiClient;

use base "Class::Data::Inheritable";

__PACKAGE__->mk_classdata('method_documentation' => {});

sub new {
    my $class = shift;
    my $api_client;

    if ($_[0] && ref $_[0] && ref $_[0] eq 'WebService::Fastly::ApiClient' ) {
        $api_client = $_[0];
    } else {
        $api_client = WebService::Fastly::ApiClient->new(@_);
    }

    bless { api_client => $api_client }, $class;

}


#
# create_log_elasticsearch
#
# Create an Elasticsearch log endpoint
#
# @param string $service_id Alphanumeric string identifying the service. (required)
# @param int $version_id Integer identifying a service version. (required)
# @param string $name The name for the real-time logging configuration. (optional)
# @param string $placement Where in the generated VCL the logging call should be placed. If not set, endpoints with &#x60;format_version&#x60; of 2 are placed in &#x60;vcl_log&#x60; and those with &#x60;format_version&#x60; of 1 are placed in &#x60;vcl_deliver&#x60;.  (optional)
# @param string $response_condition The name of an existing condition in the configured endpoint, or leave blank to always execute. (optional)
# @param string $format A Fastly [log format string](https://www.fastly.com/documentation/guides/integrations/streaming-logs/custom-log-formats/). Must produce valid JSON that Elasticsearch can ingest. (optional)
# @param string $log_processing_region The geographic region where the logs will be processed before streaming. Valid values are &#x60;us&#x60;, &#x60;eu&#x60;, and &#x60;none&#x60; for global. (optional, default to 'none')
# @param int $format_version The version of the custom logging format used for the configured endpoint. The logging call gets placed by default in &#x60;vcl_log&#x60; if &#x60;format_version&#x60; is set to &#x60;2&#x60; and in &#x60;vcl_deliver&#x60; if &#x60;format_version&#x60; is set to &#x60;1&#x60;.  (optional, default to 2)
# @param string $tls_ca_cert A secure certificate to authenticate a server with. Must be in PEM format. (optional, default to 'null')
# @param string $tls_client_cert The client certificate used to make authenticated requests. Must be in PEM format. (optional, default to 'null')
# @param string $tls_client_key The client private key used to make authenticated requests. Must be in PEM format. (optional, default to 'null')
# @param string $tls_hostname The hostname to verify the server&#39;s certificate. This should be one of the Subject Alternative Name (SAN) fields for the certificate. Common Names (CN) are not supported. (optional, default to 'null')
# @param int $request_max_entries The maximum number of logs sent in one request. Defaults &#x60;0&#x60; for unbounded. (optional, default to 0)
# @param int $request_max_bytes The maximum number of bytes sent in one request. Defaults &#x60;0&#x60; for unbounded. (optional, default to 0)
# @param string $index The name of the Elasticsearch index to send documents (logs) to. The index must follow the Elasticsearch [index format rules](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html). We support [strftime](https://www.man7.org/linux/man-pages/man3/strftime.3.html) interpolated variables inside braces prefixed with a pound symbol. For example, &#x60;#{%F}&#x60; will interpolate as &#x60;YYYY-MM-DD&#x60; with today&#39;s date. (optional)
# @param string $url The URL to stream logs to. Must use HTTPS. (optional)
# @param string $pipeline The ID of the Elasticsearch ingest pipeline to apply pre-process transformations to before indexing. Learn more about creating a pipeline in the [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest.html). (optional)
# @param string $user Basic Auth username. (optional)
# @param string $password Basic Auth password. (optional)
{
    my $params = {
    'service_id' => {
        data_type => 'string',
        description => 'Alphanumeric string identifying the service.',
        required => '1',
    },
    'version_id' => {
        data_type => 'int',
        description => 'Integer identifying a service version.',
        required => '1',
    },
    'name' => {
        data_type => 'string',
        description => 'The name for the real-time logging configuration.',
        required => '0',
    },
    'placement' => {
        data_type => 'string',
        description => 'Where in the generated VCL the logging call should be placed. If not set, endpoints with &#x60;format_version&#x60; of 2 are placed in &#x60;vcl_log&#x60; and those with &#x60;format_version&#x60; of 1 are placed in &#x60;vcl_deliver&#x60;. ',
        required => '0',
    },
    'response_condition' => {
        data_type => 'string',
        description => 'The name of an existing condition in the configured endpoint, or leave blank to always execute.',
        required => '0',
    },
    'format' => {
        data_type => 'string',
        description => 'A Fastly [log format string](https://www.fastly.com/documentation/guides/integrations/streaming-logs/custom-log-formats/). Must produce valid JSON that Elasticsearch can ingest.',
        required => '0',
    },
    'log_processing_region' => {
        data_type => 'string',
        description => 'The geographic region where the logs will be processed before streaming. Valid values are &#x60;us&#x60;, &#x60;eu&#x60;, and &#x60;none&#x60; for global.',
        required => '0',
    },
    'format_version' => {
        data_type => 'int',
        description => 'The version of the custom logging format used for the configured endpoint. The logging call gets placed by default in &#x60;vcl_log&#x60; if &#x60;format_version&#x60; is set to &#x60;2&#x60; and in &#x60;vcl_deliver&#x60; if &#x60;format_version&#x60; is set to &#x60;1&#x60;. ',
        required => '0',
    },
    'tls_ca_cert' => {
        data_type => 'string',
        description => 'A secure certificate to authenticate a server with. Must be in PEM format.',
        required => '0',
    },
    'tls_client_cert' => {
        data_type => 'string',
        description => 'The client certificate used to make authenticated requests. Must be in PEM format.',
        required => '0',
    },
    'tls_client_key' => {
        data_type => 'string',
        description => 'The client private key used to make authenticated requests. Must be in PEM format.',
        required => '0',
    },
    'tls_hostname' => {
        data_type => 'string',
        description => 'The hostname to verify the server&#39;s certificate. This should be one of the Subject Alternative Name (SAN) fields for the certificate. Common Names (CN) are not supported.',
        required => '0',
    },
    'request_max_entries' => {
        data_type => 'int',
        description => 'The maximum number of logs sent in one request. Defaults &#x60;0&#x60; for unbounded.',
        required => '0',
    },
    'request_max_bytes' => {
        data_type => 'int',
        description => 'The maximum number of bytes sent in one request. Defaults &#x60;0&#x60; for unbounded.',
        required => '0',
    },
    'index' => {
        data_type => 'string',
        description => 'The name of the Elasticsearch index to send documents (logs) to. The index must follow the Elasticsearch [index format rules](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html). We support [strftime](https://www.man7.org/linux/man-pages/man3/strftime.3.html) interpolated variables inside braces prefixed with a pound symbol. For example, &#x60;#{%F}&#x60; will interpolate as &#x60;YYYY-MM-DD&#x60; with today&#39;s date.',
        required => '0',
    },
    'url' => {
        data_type => 'string',
        description => 'The URL to stream logs to. Must use HTTPS.',
        required => '0',
    },
    'pipeline' => {
        data_type => 'string',
        description => 'The ID of the Elasticsearch ingest pipeline to apply pre-process transformations to before indexing. Learn more about creating a pipeline in the [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest.html).',
        required => '0',
    },
    'user' => {
        data_type => 'string',
        description => 'Basic Auth username.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Basic Auth password.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'create_log_elasticsearch' } = {
        summary => 'Create an Elasticsearch log endpoint',
        params => $params,
        returns => 'LoggingElasticsearchResponse',
        };
}
# @return LoggingElasticsearchResponse
#
sub create_log_elasticsearch {
    my ($self, %args) = @_;

    # verify the required parameter 'service_id' is set
    unless (exists $args{'service_id'}) {
      croak("Missing the required parameter 'service_id' when calling create_log_elasticsearch");
    }

    # verify the required parameter 'version_id' is set
    unless (exists $args{'version_id'}) {
      croak("Missing the required parameter 'version_id' when calling create_log_elasticsearch");
    }

    # parse inputs
    my $_resource_path = '/service/{service_id}/version/{version_id}/logging/elasticsearch';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/x-www-form-urlencoded');

    # path params
    if ( exists $args{'service_id'}) {
        my $_base_variable = "{" . "service_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'service_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'version_id'}) {
        my $_base_variable = "{" . "version_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'version_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # form params
    if ( exists $args{'name'} ) {
                $form_params->{'name'} = $self->{api_client}->to_form_value($args{'name'});
    }

    # form params
    if ( exists $args{'placement'} ) {
                $form_params->{'placement'} = $self->{api_client}->to_form_value($args{'placement'});
    }

    # form params
    if ( exists $args{'response_condition'} ) {
                $form_params->{'response_condition'} = $self->{api_client}->to_form_value($args{'response_condition'});
    }

    # form params
    if ( exists $args{'format'} ) {
                $form_params->{'format'} = $self->{api_client}->to_form_value($args{'format'});
    }

    # form params
    if ( exists $args{'log_processing_region'} ) {
                $form_params->{'log_processing_region'} = $self->{api_client}->to_form_value($args{'log_processing_region'});
    }

    # form params
    if ( exists $args{'format_version'} ) {
                $form_params->{'format_version'} = $self->{api_client}->to_form_value($args{'format_version'});
    }

    # form params
    if ( exists $args{'tls_ca_cert'} ) {
                $form_params->{'tls_ca_cert'} = $self->{api_client}->to_form_value($args{'tls_ca_cert'});
    }

    # form params
    if ( exists $args{'tls_client_cert'} ) {
                $form_params->{'tls_client_cert'} = $self->{api_client}->to_form_value($args{'tls_client_cert'});
    }

    # form params
    if ( exists $args{'tls_client_key'} ) {
                $form_params->{'tls_client_key'} = $self->{api_client}->to_form_value($args{'tls_client_key'});
    }

    # form params
    if ( exists $args{'tls_hostname'} ) {
                $form_params->{'tls_hostname'} = $self->{api_client}->to_form_value($args{'tls_hostname'});
    }

    # form params
    if ( exists $args{'request_max_entries'} ) {
                $form_params->{'request_max_entries'} = $self->{api_client}->to_form_value($args{'request_max_entries'});
    }

    # form params
    if ( exists $args{'request_max_bytes'} ) {
                $form_params->{'request_max_bytes'} = $self->{api_client}->to_form_value($args{'request_max_bytes'});
    }

    # form params
    if ( exists $args{'index'} ) {
                $form_params->{'index'} = $self->{api_client}->to_form_value($args{'index'});
    }

    # form params
    if ( exists $args{'url'} ) {
                $form_params->{'url'} = $self->{api_client}->to_form_value($args{'url'});
    }

    # form params
    if ( exists $args{'pipeline'} ) {
                $form_params->{'pipeline'} = $self->{api_client}->to_form_value($args{'pipeline'});
    }

    # form params
    if ( exists $args{'user'} ) {
                $form_params->{'user'} = $self->{api_client}->to_form_value($args{'user'});
    }

    # form params
    if ( exists $args{'password'} ) {
                $form_params->{'password'} = $self->{api_client}->to_form_value($args{'password'});
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(token )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LoggingElasticsearchResponse', $response);
    return $_response_object;
}

#
# delete_log_elasticsearch
#
# Delete an Elasticsearch log endpoint
#
# @param string $service_id Alphanumeric string identifying the service. (required)
# @param int $version_id Integer identifying a service version. (required)
# @param string $logging_elasticsearch_name The name for the real-time logging configuration. (required)
{
    my $params = {
    'service_id' => {
        data_type => 'string',
        description => 'Alphanumeric string identifying the service.',
        required => '1',
    },
    'version_id' => {
        data_type => 'int',
        description => 'Integer identifying a service version.',
        required => '1',
    },
    'logging_elasticsearch_name' => {
        data_type => 'string',
        description => 'The name for the real-time logging configuration.',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_log_elasticsearch' } = {
        summary => 'Delete an Elasticsearch log endpoint',
        params => $params,
        returns => 'InlineResponse200',
        };
}
# @return InlineResponse200
#
sub delete_log_elasticsearch {
    my ($self, %args) = @_;

    # verify the required parameter 'service_id' is set
    unless (exists $args{'service_id'}) {
      croak("Missing the required parameter 'service_id' when calling delete_log_elasticsearch");
    }

    # verify the required parameter 'version_id' is set
    unless (exists $args{'version_id'}) {
      croak("Missing the required parameter 'version_id' when calling delete_log_elasticsearch");
    }

    # verify the required parameter 'logging_elasticsearch_name' is set
    unless (exists $args{'logging_elasticsearch_name'}) {
      croak("Missing the required parameter 'logging_elasticsearch_name' when calling delete_log_elasticsearch");
    }

    # parse inputs
    my $_resource_path = '/service/{service_id}/version/{version_id}/logging/elasticsearch/{logging_elasticsearch_name}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type();

    # path params
    if ( exists $args{'service_id'}) {
        my $_base_variable = "{" . "service_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'service_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'version_id'}) {
        my $_base_variable = "{" . "version_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'version_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'logging_elasticsearch_name'}) {
        my $_base_variable = "{" . "logging_elasticsearch_name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'logging_elasticsearch_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(token )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('InlineResponse200', $response);
    return $_response_object;
}

#
# get_log_elasticsearch
#
# Get an Elasticsearch log endpoint
#
# @param string $service_id Alphanumeric string identifying the service. (required)
# @param int $version_id Integer identifying a service version. (required)
# @param string $logging_elasticsearch_name The name for the real-time logging configuration. (required)
{
    my $params = {
    'service_id' => {
        data_type => 'string',
        description => 'Alphanumeric string identifying the service.',
        required => '1',
    },
    'version_id' => {
        data_type => 'int',
        description => 'Integer identifying a service version.',
        required => '1',
    },
    'logging_elasticsearch_name' => {
        data_type => 'string',
        description => 'The name for the real-time logging configuration.',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_log_elasticsearch' } = {
        summary => 'Get an Elasticsearch log endpoint',
        params => $params,
        returns => 'LoggingElasticsearchResponse',
        };
}
# @return LoggingElasticsearchResponse
#
sub get_log_elasticsearch {
    my ($self, %args) = @_;

    # verify the required parameter 'service_id' is set
    unless (exists $args{'service_id'}) {
      croak("Missing the required parameter 'service_id' when calling get_log_elasticsearch");
    }

    # verify the required parameter 'version_id' is set
    unless (exists $args{'version_id'}) {
      croak("Missing the required parameter 'version_id' when calling get_log_elasticsearch");
    }

    # verify the required parameter 'logging_elasticsearch_name' is set
    unless (exists $args{'logging_elasticsearch_name'}) {
      croak("Missing the required parameter 'logging_elasticsearch_name' when calling get_log_elasticsearch");
    }

    # parse inputs
    my $_resource_path = '/service/{service_id}/version/{version_id}/logging/elasticsearch/{logging_elasticsearch_name}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type();

    # path params
    if ( exists $args{'service_id'}) {
        my $_base_variable = "{" . "service_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'service_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'version_id'}) {
        my $_base_variable = "{" . "version_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'version_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'logging_elasticsearch_name'}) {
        my $_base_variable = "{" . "logging_elasticsearch_name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'logging_elasticsearch_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(token )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LoggingElasticsearchResponse', $response);
    return $_response_object;
}

#
# list_log_elasticsearch
#
# List Elasticsearch log endpoints
#
# @param string $service_id Alphanumeric string identifying the service. (required)
# @param int $version_id Integer identifying a service version. (required)
{
    my $params = {
    'service_id' => {
        data_type => 'string',
        description => 'Alphanumeric string identifying the service.',
        required => '1',
    },
    'version_id' => {
        data_type => 'int',
        description => 'Integer identifying a service version.',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'list_log_elasticsearch' } = {
        summary => 'List Elasticsearch log endpoints',
        params => $params,
        returns => 'ARRAY[LoggingElasticsearchResponse]',
        };
}
# @return ARRAY[LoggingElasticsearchResponse]
#
sub list_log_elasticsearch {
    my ($self, %args) = @_;

    # verify the required parameter 'service_id' is set
    unless (exists $args{'service_id'}) {
      croak("Missing the required parameter 'service_id' when calling list_log_elasticsearch");
    }

    # verify the required parameter 'version_id' is set
    unless (exists $args{'version_id'}) {
      croak("Missing the required parameter 'version_id' when calling list_log_elasticsearch");
    }

    # parse inputs
    my $_resource_path = '/service/{service_id}/version/{version_id}/logging/elasticsearch';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type();

    # path params
    if ( exists $args{'service_id'}) {
        my $_base_variable = "{" . "service_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'service_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'version_id'}) {
        my $_base_variable = "{" . "version_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'version_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(token )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[LoggingElasticsearchResponse]', $response);
    return $_response_object;
}

#
# update_log_elasticsearch
#
# Update an Elasticsearch log endpoint
#
# @param string $service_id Alphanumeric string identifying the service. (required)
# @param int $version_id Integer identifying a service version. (required)
# @param string $logging_elasticsearch_name The name for the real-time logging configuration. (required)
# @param string $name The name for the real-time logging configuration. (optional)
# @param string $placement Where in the generated VCL the logging call should be placed. If not set, endpoints with &#x60;format_version&#x60; of 2 are placed in &#x60;vcl_log&#x60; and those with &#x60;format_version&#x60; of 1 are placed in &#x60;vcl_deliver&#x60;.  (optional)
# @param string $response_condition The name of an existing condition in the configured endpoint, or leave blank to always execute. (optional)
# @param string $format A Fastly [log format string](https://www.fastly.com/documentation/guides/integrations/streaming-logs/custom-log-formats/). Must produce valid JSON that Elasticsearch can ingest. (optional)
# @param string $log_processing_region The geographic region where the logs will be processed before streaming. Valid values are &#x60;us&#x60;, &#x60;eu&#x60;, and &#x60;none&#x60; for global. (optional, default to 'none')
# @param int $format_version The version of the custom logging format used for the configured endpoint. The logging call gets placed by default in &#x60;vcl_log&#x60; if &#x60;format_version&#x60; is set to &#x60;2&#x60; and in &#x60;vcl_deliver&#x60; if &#x60;format_version&#x60; is set to &#x60;1&#x60;.  (optional, default to 2)
# @param string $tls_ca_cert A secure certificate to authenticate a server with. Must be in PEM format. (optional, default to 'null')
# @param string $tls_client_cert The client certificate used to make authenticated requests. Must be in PEM format. (optional, default to 'null')
# @param string $tls_client_key The client private key used to make authenticated requests. Must be in PEM format. (optional, default to 'null')
# @param string $tls_hostname The hostname to verify the server&#39;s certificate. This should be one of the Subject Alternative Name (SAN) fields for the certificate. Common Names (CN) are not supported. (optional, default to 'null')
# @param int $request_max_entries The maximum number of logs sent in one request. Defaults &#x60;0&#x60; for unbounded. (optional, default to 0)
# @param int $request_max_bytes The maximum number of bytes sent in one request. Defaults &#x60;0&#x60; for unbounded. (optional, default to 0)
# @param string $index The name of the Elasticsearch index to send documents (logs) to. The index must follow the Elasticsearch [index format rules](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html). We support [strftime](https://www.man7.org/linux/man-pages/man3/strftime.3.html) interpolated variables inside braces prefixed with a pound symbol. For example, &#x60;#{%F}&#x60; will interpolate as &#x60;YYYY-MM-DD&#x60; with today&#39;s date. (optional)
# @param string $url The URL to stream logs to. Must use HTTPS. (optional)
# @param string $pipeline The ID of the Elasticsearch ingest pipeline to apply pre-process transformations to before indexing. Learn more about creating a pipeline in the [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest.html). (optional)
# @param string $user Basic Auth username. (optional)
# @param string $password Basic Auth password. (optional)
{
    my $params = {
    'service_id' => {
        data_type => 'string',
        description => 'Alphanumeric string identifying the service.',
        required => '1',
    },
    'version_id' => {
        data_type => 'int',
        description => 'Integer identifying a service version.',
        required => '1',
    },
    'logging_elasticsearch_name' => {
        data_type => 'string',
        description => 'The name for the real-time logging configuration.',
        required => '1',
    },
    'name' => {
        data_type => 'string',
        description => 'The name for the real-time logging configuration.',
        required => '0',
    },
    'placement' => {
        data_type => 'string',
        description => 'Where in the generated VCL the logging call should be placed. If not set, endpoints with &#x60;format_version&#x60; of 2 are placed in &#x60;vcl_log&#x60; and those with &#x60;format_version&#x60; of 1 are placed in &#x60;vcl_deliver&#x60;. ',
        required => '0',
    },
    'response_condition' => {
        data_type => 'string',
        description => 'The name of an existing condition in the configured endpoint, or leave blank to always execute.',
        required => '0',
    },
    'format' => {
        data_type => 'string',
        description => 'A Fastly [log format string](https://www.fastly.com/documentation/guides/integrations/streaming-logs/custom-log-formats/). Must produce valid JSON that Elasticsearch can ingest.',
        required => '0',
    },
    'log_processing_region' => {
        data_type => 'string',
        description => 'The geographic region where the logs will be processed before streaming. Valid values are &#x60;us&#x60;, &#x60;eu&#x60;, and &#x60;none&#x60; for global.',
        required => '0',
    },
    'format_version' => {
        data_type => 'int',
        description => 'The version of the custom logging format used for the configured endpoint. The logging call gets placed by default in &#x60;vcl_log&#x60; if &#x60;format_version&#x60; is set to &#x60;2&#x60; and in &#x60;vcl_deliver&#x60; if &#x60;format_version&#x60; is set to &#x60;1&#x60;. ',
        required => '0',
    },
    'tls_ca_cert' => {
        data_type => 'string',
        description => 'A secure certificate to authenticate a server with. Must be in PEM format.',
        required => '0',
    },
    'tls_client_cert' => {
        data_type => 'string',
        description => 'The client certificate used to make authenticated requests. Must be in PEM format.',
        required => '0',
    },
    'tls_client_key' => {
        data_type => 'string',
        description => 'The client private key used to make authenticated requests. Must be in PEM format.',
        required => '0',
    },
    'tls_hostname' => {
        data_type => 'string',
        description => 'The hostname to verify the server&#39;s certificate. This should be one of the Subject Alternative Name (SAN) fields for the certificate. Common Names (CN) are not supported.',
        required => '0',
    },
    'request_max_entries' => {
        data_type => 'int',
        description => 'The maximum number of logs sent in one request. Defaults &#x60;0&#x60; for unbounded.',
        required => '0',
    },
    'request_max_bytes' => {
        data_type => 'int',
        description => 'The maximum number of bytes sent in one request. Defaults &#x60;0&#x60; for unbounded.',
        required => '0',
    },
    'index' => {
        data_type => 'string',
        description => 'The name of the Elasticsearch index to send documents (logs) to. The index must follow the Elasticsearch [index format rules](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html). We support [strftime](https://www.man7.org/linux/man-pages/man3/strftime.3.html) interpolated variables inside braces prefixed with a pound symbol. For example, &#x60;#{%F}&#x60; will interpolate as &#x60;YYYY-MM-DD&#x60; with today&#39;s date.',
        required => '0',
    },
    'url' => {
        data_type => 'string',
        description => 'The URL to stream logs to. Must use HTTPS.',
        required => '0',
    },
    'pipeline' => {
        data_type => 'string',
        description => 'The ID of the Elasticsearch ingest pipeline to apply pre-process transformations to before indexing. Learn more about creating a pipeline in the [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest.html).',
        required => '0',
    },
    'user' => {
        data_type => 'string',
        description => 'Basic Auth username.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Basic Auth password.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'update_log_elasticsearch' } = {
        summary => 'Update an Elasticsearch log endpoint',
        params => $params,
        returns => 'LoggingElasticsearchResponse',
        };
}
# @return LoggingElasticsearchResponse
#
sub update_log_elasticsearch {
    my ($self, %args) = @_;

    # verify the required parameter 'service_id' is set
    unless (exists $args{'service_id'}) {
      croak("Missing the required parameter 'service_id' when calling update_log_elasticsearch");
    }

    # verify the required parameter 'version_id' is set
    unless (exists $args{'version_id'}) {
      croak("Missing the required parameter 'version_id' when calling update_log_elasticsearch");
    }

    # verify the required parameter 'logging_elasticsearch_name' is set
    unless (exists $args{'logging_elasticsearch_name'}) {
      croak("Missing the required parameter 'logging_elasticsearch_name' when calling update_log_elasticsearch");
    }

    # parse inputs
    my $_resource_path = '/service/{service_id}/version/{version_id}/logging/elasticsearch/{logging_elasticsearch_name}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/x-www-form-urlencoded');

    # path params
    if ( exists $args{'service_id'}) {
        my $_base_variable = "{" . "service_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'service_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'version_id'}) {
        my $_base_variable = "{" . "version_id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'version_id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'logging_elasticsearch_name'}) {
        my $_base_variable = "{" . "logging_elasticsearch_name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'logging_elasticsearch_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # form params
    if ( exists $args{'name'} ) {
                $form_params->{'name'} = $self->{api_client}->to_form_value($args{'name'});
    }

    # form params
    if ( exists $args{'placement'} ) {
                $form_params->{'placement'} = $self->{api_client}->to_form_value($args{'placement'});
    }

    # form params
    if ( exists $args{'response_condition'} ) {
                $form_params->{'response_condition'} = $self->{api_client}->to_form_value($args{'response_condition'});
    }

    # form params
    if ( exists $args{'format'} ) {
                $form_params->{'format'} = $self->{api_client}->to_form_value($args{'format'});
    }

    # form params
    if ( exists $args{'log_processing_region'} ) {
                $form_params->{'log_processing_region'} = $self->{api_client}->to_form_value($args{'log_processing_region'});
    }

    # form params
    if ( exists $args{'format_version'} ) {
                $form_params->{'format_version'} = $self->{api_client}->to_form_value($args{'format_version'});
    }

    # form params
    if ( exists $args{'tls_ca_cert'} ) {
                $form_params->{'tls_ca_cert'} = $self->{api_client}->to_form_value($args{'tls_ca_cert'});
    }

    # form params
    if ( exists $args{'tls_client_cert'} ) {
                $form_params->{'tls_client_cert'} = $self->{api_client}->to_form_value($args{'tls_client_cert'});
    }

    # form params
    if ( exists $args{'tls_client_key'} ) {
                $form_params->{'tls_client_key'} = $self->{api_client}->to_form_value($args{'tls_client_key'});
    }

    # form params
    if ( exists $args{'tls_hostname'} ) {
                $form_params->{'tls_hostname'} = $self->{api_client}->to_form_value($args{'tls_hostname'});
    }

    # form params
    if ( exists $args{'request_max_entries'} ) {
                $form_params->{'request_max_entries'} = $self->{api_client}->to_form_value($args{'request_max_entries'});
    }

    # form params
    if ( exists $args{'request_max_bytes'} ) {
                $form_params->{'request_max_bytes'} = $self->{api_client}->to_form_value($args{'request_max_bytes'});
    }

    # form params
    if ( exists $args{'index'} ) {
                $form_params->{'index'} = $self->{api_client}->to_form_value($args{'index'});
    }

    # form params
    if ( exists $args{'url'} ) {
                $form_params->{'url'} = $self->{api_client}->to_form_value($args{'url'});
    }

    # form params
    if ( exists $args{'pipeline'} ) {
                $form_params->{'pipeline'} = $self->{api_client}->to_form_value($args{'pipeline'});
    }

    # form params
    if ( exists $args{'user'} ) {
                $form_params->{'user'} = $self->{api_client}->to_form_value($args{'user'});
    }

    # form params
    if ( exists $args{'password'} ) {
                $form_params->{'password'} = $self->{api_client}->to_form_value($args{'password'});
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(token )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LoggingElasticsearchResponse', $response);
    return $_response_object;
}

1;
