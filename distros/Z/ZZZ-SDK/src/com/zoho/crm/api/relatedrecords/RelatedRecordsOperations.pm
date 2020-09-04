require 'src/com/zoho/crm/api/Header.pm';
require 'src/com/zoho/crm/api/HeaderMap.pm';
require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Utility.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package relatedrecords::RelatedRecordsOperations;
use Moose;
sub new
{
	my ($class,$module_api_name,$record_id,$related_list_api_name) = @_;
	my $self = 
	{
		module_api_name => $module_api_name,
		record_id => $record_id,
		related_list_api_name => $related_list_api_name,
	};
	bless $self,$class;
	return $self;
}
sub get_related_records
{
	my ($self,$param_instance,$header_instance) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	if((defined($header_instance))&&(!(($header_instance)->isa("HeaderMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: header_instance EXPECTED TYPE: HeaderMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_header($header_instance); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ResponseHandler", "application/json"); 
}

sub update_related_records
{
	my ($self,$request) = @_;
	if(!(($request)->isa("relatedrecords::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: relatedrecords::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ActionHandler", "application/json"); 
}

sub delink_records
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
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_param($param_instance); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ActionHandler", "application/json"); 
}

sub get_related_record
{
	my ($self,$header_instance,$related_record_id) = @_;
	if((defined($header_instance))&&(!(($header_instance)->isa("HeaderMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: header_instance EXPECTED TYPE: HeaderMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$related_record_id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_header($header_instance); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ResponseHandler", "application/json"); 
}

sub update_related_record
{
	my ($self,$request,$related_record_id) = @_;
	if(!(($request)->isa("relatedrecords::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: relatedrecords::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$related_record_id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ActionHandler", "application/json"); 
}

sub delink_record
{
	my ($self,$related_record_id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{related_list_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$related_record_id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	Utility::get_related_lists($self->{related_list_api_name}, $self->{module_api_name}, $handler_instance); 
	return $handler_instance->api_call("relatedrecords.ActionHandler", "application/json"); 
}

package relatedrecords::GetRelatedRecordsParam;
sub page
{
	return Param->new("page", "com.zoho.crm.api.RelatedRecords.GetRelatedRecordsParam"); 
}

sub per_page
{
	return Param->new("per_page", "com.zoho.crm.api.RelatedRecords.GetRelatedRecordsParam"); 
}




package relatedrecords::GetRelatedRecordsHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.RelatedRecords.GetRelatedRecordsHeader"); 
}




package relatedrecords::DelinkRecordsParam;
sub ids
{
	return Param->new("ids", "com.zoho.crm.api.RelatedRecords.DelinkRecordsParam"); 
}




package relatedrecords::GetRelatedRecordHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.RelatedRecords.GetRelatedRecordHeader"); 
}


1;