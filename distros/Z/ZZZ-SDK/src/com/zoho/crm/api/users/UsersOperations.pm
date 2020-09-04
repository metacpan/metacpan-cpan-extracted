require 'src/com/zoho/crm/api/Header.pm';
require 'src/com/zoho/crm/api/HeaderMap.pm';
require 'src/com/zoho/crm/api/Param.pm';
require 'src/com/zoho/crm/api/ParameterMap.pm';
require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package users::UsersOperations;
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
sub get_users
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
	$api_path = $api_path . "/crm/v2/users"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_param($param_instance); 
	$handler_instance->set_header($header_instance); 
	return $handler_instance->api_call("users.ResponseHandler", "application/json"); 
}

sub create_user
{
	my ($self,$request) = @_;
	if(!(($request)->isa("users::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: users::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/users"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_POST); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_CREATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("users.ActionHandler", "application/json"); 
}

sub update_users
{
	my ($self,$request) = @_;
	if(!(($request)->isa("users::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: users::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/users"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("users.ActionHandler", "application/json"); 
}

sub get_user
{
	my ($self,$header_instance,$id) = @_;
	if((defined($header_instance))&&(!(($header_instance)->isa("HeaderMap"))))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: header_instance EXPECTED TYPE: HeaderMap", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/users/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->set_header($header_instance); 
	return $handler_instance->api_call("users.ResponseHandler", "application/json"); 
}

sub update_user
{
	my ($self,$request,$id) = @_;
	if(!(($request)->isa("users::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: users::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/users/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	return $handler_instance->api_call("users.ActionHandler", "application/json"); 
}

sub delete_user
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/users/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_DELETE); 
	$handler_instance->set_category_method($Constants::REQUEST_METHOD_DELETE); 
	return $handler_instance->api_call("users.ActionHandler", "application/json"); 
}

package users::GetUsersParam;
sub type
{
	return Param->new("type", "com.zoho.crm.api.Users.GetUsersParam"); 
}

sub page
{
	return Param->new("page", "com.zoho.crm.api.Users.GetUsersParam"); 
}

sub per_page
{
	return Param->new("per_page", "com.zoho.crm.api.Users.GetUsersParam"); 
}




package users::GetUsersHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.Users.GetUsersHeader"); 
}




package users::GetUserHeader;
sub If_modified_since
{
	return Header->new("If-Modified-Since", "com.zoho.crm.api.Users.GetUserHeader"); 
}


1;