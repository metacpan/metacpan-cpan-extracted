require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package sharerecords::ShareRecordsOperations;
use Moose;
sub new
{
	my ($class,$module_api_name,$record_id) = @_;
	my $self = 
	{
		module_api_name => $module_api_name,
		record_id => $record_id,
	};
	bless $self,$class;
	return $self;
}
sub get_shared_record_details
{
	my ($self,$param_instance) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/share"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("sharerecords.ResponseHandler", "application/json"); 
}

sub share_record
{
	my ($self,$request) = @_;
	if(!(($request)->isa("sharerecords::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: sharerecords::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/share"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("sharerecords.ActionHandler", "application/json"); 
}

sub update_share_permissions
{
	my ($self,$request) = @_;
	if(!(($request)->isa("sharerecords::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: sharerecords::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/share"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("sharerecords.ActionHandler", "application/json"); 
}

sub revoke_shared_record
{
	my ($self) = shift;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/share"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	return $handler_instance->api_call("sharerecords.DeleteActionHandler", "application/json"); 
}

package sharerecords::GetSharedRecordDetailsParam;
sub sharedTo
{
	return Param->new("sharedTo", "com.zoho.crm.api.ShareRecords.GetSharedRecordDetailsParam"); 
}

sub view
{
	return Param->new("view", "com.zoho.crm.api.ShareRecords.GetSharedRecordDetailsParam"); 
}


1;