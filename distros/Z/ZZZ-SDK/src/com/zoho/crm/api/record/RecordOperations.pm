require 'src/com/zoho/crm/api/Header.pm';
require 'src/com/zoho/crm/api/HeaderMap.pm';
require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Utility.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::RecordOperations;
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
sub get_record
{
	my ($self,$param_instance,$header_instance,$module_api_name,$id) = @_;
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
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_header($header_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ResponseHandler", "application/json"); 
}

sub update_record
{
	my ($self,$request,$module_api_name,$id) = @_;
	if(!(($request)->isa("record::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub delete_record
{
	my ($self,$param_instance,$module_api_name,$id) = @_;
	if((defined($param_instance))&&(!(($param_instance)->isa("ParameterMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: param_instance EXPECTED TYPE: ParameterMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_param($param_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub get_records
{
	my ($self,$param_instance,$header_instance,$module_api_name) = @_;
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
	$api_path = $api_path . "".$module_api_name; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_header($header_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ResponseHandler", "application/json"); 
}

sub create_records
{
	my ($self,$request,$module_api_name) = @_;
	if(!(($request)->isa("record::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub update_records
{
	my ($self,$request,$module_api_name) = @_;
	if(!(($request)->isa("record::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub delete_records
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
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_param($param_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub upsert_records
{
	my ($self,$request,$module_api_name) = @_;
	if(!(($request)->isa("record::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/upsert"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method("ACTION"); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ActionHandler", "application/json"); 
}

sub get_deleted_records
{
	my ($self,$param_instance,$header_instance,$module_api_name) = @_;
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
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/deleted"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_header($header_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.DeletedRecordsHandler", "application/json"); 
}

sub search_records
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
	$api_path = $api_path . "/search"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.ResponseHandler", "application/json"); 
}

sub convert_lead
{
	my ($self,$request,$id) = @_;
	if(!(($request)->isa("record::ConvertBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::ConvertBodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/Leads/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/actions/convert"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	Utility::get_fields("Deals");
	return $handler_instance->api_call("record.ConvertActionHandler", "application/json"); 
}

sub get_photo
{
	my ($self,$module_api_name,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/photo"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("record.DownloadHandler", "application/x-download"); 
}

sub upload_photo
{
	my ($self,$request,$module_api_name,$id) = @_;
	if(!(($request)->isa("record::FileBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::FileBodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/photo"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("multipart/form-data"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("record.FileHandler", "application/json"); 
}

sub delete_photo
{
	my ($self,$module_api_name,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . "".$id; 
	$api_path = $api_path . "/photo"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	return $handler_instance->api_call("record.FileHandler", "application/json"); 
}

sub mass_update_records
{
	my ($self,$request,$module_api_name) = @_;
	if(!(($request)->isa("record::MassUpdateBodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: record::MassUpdateBodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . "".$module_api_name; 
	$api_path = $api_path . "/actions/mass_update"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	Utility::get_fields($module_api_name); 
	$handler_instance->set_module_api_name($module_api_name); 
	return $handler_instance->api_call("record.MassUpdateActionHandler", "application/json"); 
}

sub get_mass_update_status
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
	$api_path = $api_path . "/actions/mass_update"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	return $handler_instance->api_call("record.MassUpdateResponseHandler", "application/json"); 
}

package record::GetRecordParam;
sub approved
{
	return Param->new("approved", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub converted
{
	return Param->new("converted", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub cvid
{
	return Param->new("cvid", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub uid
{
	return Param->new("uid", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub fields
{
	return Param->new("fields", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub startDateTime
{
	return Param->new("startDateTime", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub endDateTime
{
	return Param->new("endDateTime", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub territory_id
{
	return Param->new("territory_id", "com.zoho.crm.api.Record.GetRecordParam"); 
}

sub include_child
{
	return Param->new("include_child", "com.zoho.crm.api.Record.GetRecordParam"); 
}




package record::GetRecordHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.Record.GetRecordHeader"); 
}




package record::DeleteRecordParam;
sub wf_trigger
{
	return Param->new("wf_trigger", "com.zoho.crm.api.Record.DeleteRecordParam"); 
}




package record::GetRecordsParam;
sub approved
{
	return Param->new("approved", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub converted
{
	return Param->new("converted", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub cvid
{
	return Param->new("cvid", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub ids
{
	return Param->new("ids", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub uid
{
	return Param->new("uid", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub fields
{
	return Param->new("fields", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub sort_by
{
	return Param->new("sort_by", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub sort_order
{
	return Param->new("sort_order", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub page
{
	return Param->new("page", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub per_page
{
	return Param->new("per_page", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub startDateTime
{
	return Param->new("startDateTime", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub endDateTime
{
	return Param->new("endDateTime", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub territory_id
{
	return Param->new("territory_id", "com.zoho.crm.api.Record.GetRecordsParam"); 
}

sub include_child
{
	return Param->new("include_child", "com.zoho.crm.api.Record.GetRecordsParam"); 
}




package record::GetRecordsHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.Record.GetRecordsHeader"); 
}




package record::DeleteRecordsParam;
sub ids
{
	return Param->new("ids", "com.zoho.crm.api.Record.DeleteRecordsParam"); 
}

sub wf_trigger
{
	return Param->new("wf_trigger", "com.zoho.crm.api.Record.DeleteRecordsParam"); 
}




package record::GetDeletedRecordsParam;
sub type
{
	return Param->new("type", "com.zoho.crm.api.Record.GetDeletedRecordsParam"); 
}

sub page
{
	return Param->new("page", "com.zoho.crm.api.Record.GetDeletedRecordsParam"); 
}

sub per_page
{
	return Param->new("per_page", "com.zoho.crm.api.Record.GetDeletedRecordsParam"); 
}




package record::GetDeletedRecordsHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.Record.GetDeletedRecordsHeader"); 
}




package record::SearchRecordsParam;
sub criteria
{
	return Param->new("criteria", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub email
{
	return Param->new("email", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub phone
{
	return Param->new("phone", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub word
{
	return Param->new("word", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub converted
{
	return Param->new("converted", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub approved
{
	return Param->new("approved", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub page
{
	return Param->new("page", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}

sub per_page
{
	return Param->new("per_page", "com.zoho.crm.api.Record.SearchRecordsParam"); 
}




package record::GetMassUpdateStatusParam;
sub job_id
{
	return Param->new("job_id", "com.zoho.crm.api.Record.GetMassUpdateStatusParam"); 
}


1;