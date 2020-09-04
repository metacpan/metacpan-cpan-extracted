require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package variablegroups::VariableGroupsOperations;
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
sub get_variable_groups
{
	my ($self) = shift;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/variable_groups"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("variablegroups.ResponseHandler", "application/json"); 
}

sub get_variable_group_by_id
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/variable_groups/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("variablegroups.ResponseHandler", "application/json"); 
}

sub get_variable_group_by_api_name
{
	my ($self,$api_name) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/variable_groups/"; 
	$api_path = $api_path . "".$api_name; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("variablegroups.ResponseHandler", "application/json"); 
}
1;