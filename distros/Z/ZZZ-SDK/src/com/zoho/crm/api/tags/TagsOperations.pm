require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package tags::TagsOperations;
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
sub get_tags
{
	my ($self,$param_instance) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("tags.ResponseHandler", "application/json"); 
}

sub create_tags
{
	my ($self,$request,$param_instance) = @_;
	if(!(($request)->isa("tags::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: tags::BodyWrapper", undef, undef); 
	}
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.ActionHandler", "application/json"); 
}

sub update_tags
{
	my ($self,$request,$param_instance) = @_;
	if(!(($request)->isa("tags::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: tags::BodyWrapper", undef, undef); 
	}
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.ActionHandler", "application/json"); 
}

sub update_tag
{
	my ($self,$request,$param_instance,$id) = @_;
	if(!(($request)->isa("tags::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: tags::BodyWrapper", undef, undef); 
	}
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("tags.ActionHandler", "application/json"); 
}

sub delete_tag
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	return $handler_instance->api_call("tags.ActionHandler", "application/json"); 
}

sub merge_tags
{
	my ($self,$request,$id) = @_;
	if(!(($request)->isa("tags::MergeWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: tags::MergeWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/actions/merge"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.ActionHandler", "application/json"); 
}

sub add_tags_to_record
{
	my ($self,$param_instance,$module_api_name,$record_id) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$record_id; 
	$api_path = $api_path . "/actions/add_tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.RecordActionHandler", "application/json"); 
}

sub remove_tags_from_record
{
	my ($self,$param_instance,$module_api_name,$record_id) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$record_id; 
	$api_path = $api_path . "/actions/remove_tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.RecordActionHandler", "application/json"); 
}

sub add_tags_to_multiple_records
{
	my ($self,$param_instance,$module_api_name) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/actions/add_tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.RecordActionHandler", "application/json"); 
}

sub remove_tags_from_multiple_records
{
	my ($self,$param_instance,$module_api_name) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/actions/remove_tags"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("tags.RecordActionHandler", "application/json"); 
}

sub get_record_count_for_tag
{
	my ($self,$param_instance,$id) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/tags/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/actions/records_count"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("tags.CountHandler", "application/json"); 
}

package tags::GetTagsParam;
sub module
{
	return Param->new("module", "com.zoho.crm.api.Tags.GetTagsParam"); 
}

sub my_tags
{
	return Param->new("my_tags", "com.zoho.crm.api.Tags.GetTagsParam"); 
}




package tags::CreateTagsParam;
sub module
{
	return Param->new("module", "com.zoho.crm.api.Tags.CreateTagsParam"); 
}




package tags::UpdateTagsParam;
sub module
{
	return Param->new("module", "com.zoho.crm.api.Tags.UpdateTagsParam"); 
}




package tags::UpdateTagParam;
sub module
{
	return Param->new("module", "com.zoho.crm.api.Tags.UpdateTagParam"); 
}




package tags::AddTagsToRecordParam;
sub tag_names
{
	return Param->new("tag_names", "com.zoho.crm.api.Tags.AddTagsToRecordParam"); 
}

sub over_write
{
	return Param->new("over_write", "com.zoho.crm.api.Tags.AddTagsToRecordParam"); 
}




package tags::RemoveTagsFromRecordParam;
sub tag_names
{
	return Param->new("tag_names", "com.zoho.crm.api.Tags.RemoveTagsFromRecordParam"); 
}




package tags::AddTagsToMultipleRecordsParam;
sub tag_names
{
	return Param->new("tag_names", "com.zoho.crm.api.Tags.AddTagsToMultipleRecordsParam"); 
}

sub ids
{
	return Param->new("ids", "com.zoho.crm.api.Tags.AddTagsToMultipleRecordsParam"); 
}

sub over_write
{
	return Param->new("over_write", "com.zoho.crm.api.Tags.AddTagsToMultipleRecordsParam"); 
}




package tags::RemoveTagsFromMultipleRecordsParam;
sub tag_names
{
	return Param->new("tag_names", "com.zoho.crm.api.Tags.RemoveTagsFromMultipleRecordsParam"); 
}

sub ids
{
	return Param->new("ids", "com.zoho.crm.api.Tags.RemoveTagsFromMultipleRecordsParam"); 
}




package tags::GetRecordCountForTagParam;
sub module
{
	return Param->new("module", "com.zoho.crm.api.Tags.GetRecordCountForTagParam"); 
}


1;