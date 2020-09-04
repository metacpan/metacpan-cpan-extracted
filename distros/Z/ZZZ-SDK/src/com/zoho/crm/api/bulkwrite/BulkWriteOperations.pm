require 'src/com/zoho/crm/api/Header.pm';
require 'src/com/zoho/crm/api/HeaderMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package bulkwrite::BulkWriteOperations;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
	};
	bless $self,$class;
	return $self;
}
sub upload_file
{
	my ($self,$request,$header_instance) = @_;
	if(!(($request)->isa("bulkwrite::FileBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: bulkwrite::FileBodyWrapper", undef, undef); 
	}
	if((defined($header_instance))&&(!(($header_instance)->isa("HeaderMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: header_instance EXPECTED TYPE: HeaderMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "https://content.zohoapis.com/crm/v2/upload"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("multipart/form-data"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	$handler_instance->set_header($header_instance); 
	return $handler_instance->api_call("bulkwrite.ActionResponse", "application/json"); 
}

sub create_bulk_write_job
{
	my ($self,$request) = @_;
	if(!(($request)->isa("bulkwrite::RequestWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: bulkwrite::RequestWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/bulk/v2/write"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("bulkwrite.ActionResponse", "application/json"); 
}

sub get_bulk_write_job_details
{
	my ($self,$job_id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/bulk/v2/write/"; 
	$api_path = $api_path . "".$job_id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("bulkwrite.ResponseWrapper", "application/json"); 
}

sub download_bulk_write_result
{
	my ($self,$download_url) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$download_url; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("bulkwrite.ResponseHandler", "application/octet-stream"); 
}

package bulkwrite::UploadFileHeader;
sub feature
{
	return Header->new("feature", "com.zoho.crm.api.BulkWrite.UploadFileHeader"); 
}

sub X_crm_org
{
	return Header->new("X-CRM-ORG", "com.zoho.crm.api.BulkWrite.UploadFileHeader"); 
}


1;