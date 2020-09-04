require 'src/com/zoho/crm/api/util/APIResponse.pm';
require 'src/com/zoho/crm/api/util/CommonAPIHandler.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package customviews::CustomViewsOperations;
use Moose;
sub new
{
	my ($class,$module) = @_;
	my $self = 
	{
		module => $module,
	};
	bless $self,$class;
	return $self;
}
sub get_custom_views
{
	my ($self) = shift;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/custom_views"; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->add_param("module", $self->{module}); 
	return $handler_instance->api_call("customviews.ResponseHandler", "application/json"); 
}

sub get_custom_view
{
	my ($self,$id) = @_;
	my $handler_instance = CommonAPIHandler->new(); 
	my $api_path = ""; 
	$api_path = $api_path . "/crm/v2/settings/custom_views/"; 
	$api_path = $api_path . "".$id; 
	$handler_instance->set_api_path($api_path); 
	$handler_instance->set_http_method($Constants::REQUEST_METHOD_GET); 
	$handler_instance->set_category_method($Constants::REQUEST_CATEGORY_READ); 
	$handler_instance->add_param("module", $self->{module}); 
	return $handler_instance->api_call("customviews.ResponseHandler", "application/json"); 
}
1;