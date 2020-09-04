require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package blueprint::BluePrintOperations;
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
sub get_blueprint
{
	my ($self) = shift;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/blueprint"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	return $handler_instance->api_call("blueprint.ResponseHandler", "application/json"); 
}

sub update_blueprint
{
	my ($self,$request) = @_;
	if(!(($request)->isa("blueprint::BodyWrapper")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: request EXPECTED TYPE: blueprint::BodyWrapper", undef, undef); 
	}
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/"; 
	$api_path = $api_path . $self->{module_api_name}; 
	$api_path = $api_path . "/"; 
	$api_path = $api_path . $self->{record_id}; 
	$api_path = $api_path . "/actions/blueprint"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_PUT); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_UPDATE); 
	$handler_instance->set_content_type("application/json"); 
	$handler_instance->set_request($request); 
	$handler_instance->set_mandatory_checker(1); 
	return $handler_instance->api_call("blueprint.ActionResponse", "application/json"); 
}
1;