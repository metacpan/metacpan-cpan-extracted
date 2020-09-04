require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package attachments::AttachmentsOperations;
use Moose;
sub new
{
	my ($class,$record_id,$module_api_name) = @_;
	my $self = 
	{
		record_id => $record_id,
		module_api_name => $module_api_name,
	};
	bless $self,$class;
	return $self;
}
sub download_attachment
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/Attachments/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("attachments.ResponseHandler", "application/x-download"); 
}

sub delete_attachment
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/Attachments/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	return $handler_instance->api_call("attachments.ActionHandler", "application/json"); 
}

sub get_attachments
{
	my ($self) = shift;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/Attachments"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("attachments.ResponseHandler", "application/json"); 
}

sub upload_attachment
{
	my ($self,$request) = @_;
	if(!(($request)->isa("attachments::FileBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: attachments::FileBodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/Attachments"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("multipart/form-data"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("attachments.ActionHandler", "application/json"); 
}

sub upload_link_attachment
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
	$api_path = $api_path . "/Attachments"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("attachments.ActionHandler", "application/json"); 
}

sub delete_attachments
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
	$api_path = $api_path . "/Attachments"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("attachments.ActionHandler", "application/json"); 
}

package attachments::UploadLinkAttachmentParam;
sub attachmentUrl
{
	return Param->new("attachmentUrl", "com.zoho.crm.api.Attachments.UploadLinkAttachmentParam"); 
}




package attachments::DeleteAttachmentsParam;
sub ids
{
	return Param->new("ids", "com.zoho.crm.api.Attachments.DeleteAttachmentsParam"); 
}


1;