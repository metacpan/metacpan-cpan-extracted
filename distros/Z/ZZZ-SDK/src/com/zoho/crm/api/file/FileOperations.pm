require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package file::FileOperations;
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
	my ($self,$request) = @_;
	if(!(($request)->isa("file::FileBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: file::FileBodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/files"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("multipart/form-data"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("file.ActionHandler", "application/json"); 
}

sub get_file
{
	my ($self,$param_instance) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/files"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("file.ResponseHandler", "application/x-download"); 
}

package file::GetFileParam;
sub id
{
	return Param->new("id", "com.zoho.crm.api.File.GetFileParam"); 
}


1;