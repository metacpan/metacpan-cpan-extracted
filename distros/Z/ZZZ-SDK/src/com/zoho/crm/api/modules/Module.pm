require 'src/com/zoho/crm/api/customviews/CustomView.pm';
require 'src/com/zoho/crm/api/profiles/Profile.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package modules::Module;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		name => undef,
		global_search_supported => undef,
		kanban_view => undef,
		deletable => undef,
		description => undef,
		creatable => undef,
		filter_status => undef,
		inventory_template_supported => undef,
		modified_time => undef,
		plural_label => undef,
		presence_sub_menu => undef,
		triggers_supported => undef,
		id => undef,
		related_list_properties => undef,
		properties => undef,
		per_page => undef,
		visibility => undef,
		convertable => undef,
		editable => undef,
		emailtemplate_support => undef,
		profiles => undef,
		filter_supported => undef,
		display_field => undef,
		search_layout_fields => undef,
		kanban_view_supported => undef,
		show_as_tab => undef,
		web_link => undef,
		sequence_number => undef,
		singular_label => undef,
		viewable => undef,
		api_supported => undef,
		api_name => undef,
		quick_create => undef,
		modified_by => undef,
		generated_type => undef,
		feeds_required => undef,
		scoring_supported => undef,
		webform_supported => undef,
		arguments => undef,
		module_name => undef,
		business_card_field_limit => undef,
		custom_view => undef,
		parent_module => undef,
		territory => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_name
{
	my ($self) = shift;
	return $self->{name}; 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->{name} = $name; 
	$self->{key_modified}{"name"} = 1; 
}

sub get_global_search_supported
{
	my ($self) = shift;
	return $self->{global_search_supported}; 
}

sub set_global_search_supported
{
	my ($self,$global_search_supported) = @_;
	$self->{global_search_supported} = $global_search_supported; 
	$self->{key_modified}{"global_search_supported"} = 1; 
}

sub get_kanban_view
{
	my ($self) = shift;
	return $self->{kanban_view}; 
}

sub set_kanban_view
{
	my ($self,$kanban_view) = @_;
	$self->{kanban_view} = $kanban_view; 
	$self->{key_modified}{"kanban_view"} = 1; 
}

sub get_deletable
{
	my ($self) = shift;
	return $self->{deletable}; 
}

sub set_deletable
{
	my ($self,$deletable) = @_;
	$self->{deletable} = $deletable; 
	$self->{key_modified}{"deletable"} = 1; 
}

sub get_description
{
	my ($self) = shift;
	return $self->{description}; 
}

sub set_description
{
	my ($self,$description) = @_;
	$self->{description} = $description; 
	$self->{key_modified}{"description"} = 1; 
}

sub get_creatable
{
	my ($self) = shift;
	return $self->{creatable}; 
}

sub set_creatable
{
	my ($self,$creatable) = @_;
	$self->{creatable} = $creatable; 
	$self->{key_modified}{"creatable"} = 1; 
}

sub get_filter_status
{
	my ($self) = shift;
	return $self->{filter_status}; 
}

sub set_filter_status
{
	my ($self,$filter_status) = @_;
	$self->{filter_status} = $filter_status; 
	$self->{key_modified}{"filter_status"} = 1; 
}

sub get_inventory_template_supported
{
	my ($self) = shift;
	return $self->{inventory_template_supported}; 
}

sub set_inventory_template_supported
{
	my ($self,$inventory_template_supported) = @_;
	$self->{inventory_template_supported} = $inventory_template_supported; 
	$self->{key_modified}{"inventory_template_supported"} = 1; 
}

sub get_modified_time
{
	my ($self) = shift;
	return $self->{modified_time}; 
}

sub set_modified_time
{
	my ($self,$modified_time) = @_;
	if(!(($modified_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{modified_time} = $modified_time; 
	$self->{key_modified}{"modified_time"} = 1; 
}

sub get_plural_label
{
	my ($self) = shift;
	return $self->{plural_label}; 
}

sub set_plural_label
{
	my ($self,$plural_label) = @_;
	$self->{plural_label} = $plural_label; 
	$self->{key_modified}{"plural_label"} = 1; 
}

sub get_presence_sub_menu
{
	my ($self) = shift;
	return $self->{presence_sub_menu}; 
}

sub set_presence_sub_menu
{
	my ($self,$presence_sub_menu) = @_;
	$self->{presence_sub_menu} = $presence_sub_menu; 
	$self->{key_modified}{"presence_sub_menu"} = 1; 
}

sub get_triggers_supported
{
	my ($self) = shift;
	return $self->{triggers_supported}; 
}

sub set_triggers_supported
{
	my ($self,$triggers_supported) = @_;
	$self->{triggers_supported} = $triggers_supported; 
	$self->{key_modified}{"triggers_supported"} = 1; 
}

sub get_id
{
	my ($self) = shift;
	return $self->{id}; 
}

sub set_id
{
	my ($self,$id) = @_;
	$self->{id} = $id; 
	$self->{key_modified}{"id"} = 1; 
}

sub get_related_list_properties
{
	my ($self) = shift;
	return $self->{related_list_properties}; 
}

sub set_related_list_properties
{
	my ($self,$related_list_properties) = @_;
	if(!(($related_list_properties)->isa("modules::RelatedListProperties")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: related_list_properties EXPECTED TYPE: modules::RelatedListProperties", undef, undef); 
	}
	$self->{related_list_properties} = $related_list_properties; 
	$self->{key_modified}{"related_list_properties"} = 1; 
}

sub get_properties
{
	my ($self) = shift;
	return $self->{properties}; 
}

sub set_properties
{
	my ($self,$properties) = @_;
	if(!(ref($properties) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: properties EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{properties} = $properties; 
	$self->{key_modified}{"\$properties"} = 1; 
}

sub get_per_page
{
	my ($self) = shift;
	return $self->{per_page}; 
}

sub set_per_page
{
	my ($self,$per_page) = @_;
	$self->{per_page} = $per_page; 
	$self->{key_modified}{"per_page"} = 1; 
}

sub get_visibility
{
	my ($self) = shift;
	return $self->{visibility}; 
}

sub set_visibility
{
	my ($self,$visibility) = @_;
	$self->{visibility} = $visibility; 
	$self->{key_modified}{"visibility"} = 1; 
}

sub get_convertable
{
	my ($self) = shift;
	return $self->{convertable}; 
}

sub set_convertable
{
	my ($self,$convertable) = @_;
	$self->{convertable} = $convertable; 
	$self->{key_modified}{"convertable"} = 1; 
}

sub get_editable
{
	my ($self) = shift;
	return $self->{editable}; 
}

sub set_editable
{
	my ($self,$editable) = @_;
	$self->{editable} = $editable; 
	$self->{key_modified}{"editable"} = 1; 
}

sub get_emailtemplate_support
{
	my ($self) = shift;
	return $self->{emailtemplate_support}; 
}

sub set_emailtemplate_support
{
	my ($self,$emailtemplate_support) = @_;
	$self->{emailtemplate_support} = $emailtemplate_support; 
	$self->{key_modified}{"emailTemplate_support"} = 1; 
}

sub get_profiles
{
	my ($self) = shift;
	return $self->{profiles}; 
}

sub set_profiles
{
	my ($self,$profiles) = @_;
	if(!(ref($profiles) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: profiles EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{profiles} = $profiles; 
	$self->{key_modified}{"profiles"} = 1; 
}

sub get_filter_supported
{
	my ($self) = shift;
	return $self->{filter_supported}; 
}

sub set_filter_supported
{
	my ($self,$filter_supported) = @_;
	$self->{filter_supported} = $filter_supported; 
	$self->{key_modified}{"filter_supported"} = 1; 
}

sub get_display_field
{
	my ($self) = shift;
	return $self->{display_field}; 
}

sub set_display_field
{
	my ($self,$display_field) = @_;
	$self->{display_field} = $display_field; 
	$self->{key_modified}{"display_field"} = 1; 
}

sub get_search_layout_fields
{
	my ($self) = shift;
	return $self->{search_layout_fields}; 
}

sub set_search_layout_fields
{
	my ($self,$search_layout_fields) = @_;
	if(!(ref($search_layout_fields) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: search_layout_fields EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{search_layout_fields} = $search_layout_fields; 
	$self->{key_modified}{"search_layout_fields"} = 1; 
}

sub get_kanban_view_supported
{
	my ($self) = shift;
	return $self->{kanban_view_supported}; 
}

sub set_kanban_view_supported
{
	my ($self,$kanban_view_supported) = @_;
	$self->{kanban_view_supported} = $kanban_view_supported; 
	$self->{key_modified}{"kanban_view_supported"} = 1; 
}

sub get_show_as_tab
{
	my ($self) = shift;
	return $self->{show_as_tab}; 
}

sub set_show_as_tab
{
	my ($self,$show_as_tab) = @_;
	$self->{show_as_tab} = $show_as_tab; 
	$self->{key_modified}{"show_as_tab"} = 1; 
}

sub get_web_link
{
	my ($self) = shift;
	return $self->{web_link}; 
}

sub set_web_link
{
	my ($self,$web_link) = @_;
	$self->{web_link} = $web_link; 
	$self->{key_modified}{"web_link"} = 1; 
}

sub get_sequence_number
{
	my ($self) = shift;
	return $self->{sequence_number}; 
}

sub set_sequence_number
{
	my ($self,$sequence_number) = @_;
	$self->{sequence_number} = $sequence_number; 
	$self->{key_modified}{"sequence_number"} = 1; 
}

sub get_singular_label
{
	my ($self) = shift;
	return $self->{singular_label}; 
}

sub set_singular_label
{
	my ($self,$singular_label) = @_;
	$self->{singular_label} = $singular_label; 
	$self->{key_modified}{"singular_label"} = 1; 
}

sub get_viewable
{
	my ($self) = shift;
	return $self->{viewable}; 
}

sub set_viewable
{
	my ($self,$viewable) = @_;
	$self->{viewable} = $viewable; 
	$self->{key_modified}{"viewable"} = 1; 
}

sub get_api_supported
{
	my ($self) = shift;
	return $self->{api_supported}; 
}

sub set_api_supported
{
	my ($self,$api_supported) = @_;
	$self->{api_supported} = $api_supported; 
	$self->{key_modified}{"api_supported"} = 1; 
}

sub get_api_name
{
	my ($self) = shift;
	return $self->{api_name}; 
}

sub set_api_name
{
	my ($self,$api_name) = @_;
	$self->{api_name} = $api_name; 
	$self->{key_modified}{"api_name"} = 1; 
}

sub get_quick_create
{
	my ($self) = shift;
	return $self->{quick_create}; 
}

sub set_quick_create
{
	my ($self,$quick_create) = @_;
	$self->{quick_create} = $quick_create; 
	$self->{key_modified}{"quick_create"} = 1; 
}

sub get_modified_by
{
	my ($self) = shift;
	return $self->{modified_by}; 
}

sub set_modified_by
{
	my ($self,$modified_by) = @_;
	if(!(($modified_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: modified_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{modified_by} = $modified_by; 
	$self->{key_modified}{"modified_by"} = 1; 
}

sub get_generated_type
{
	my ($self) = shift;
	return $self->{generated_type}; 
}

sub set_generated_type
{
	my ($self,$generated_type) = @_;
	if(!(($generated_type)->isa("Choice")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: generated_type EXPECTED TYPE: Choice", undef, undef); 
	}
	$self->{generated_type} = $generated_type; 
	$self->{key_modified}{"generated_type"} = 1; 
}

sub get_feeds_required
{
	my ($self) = shift;
	return $self->{feeds_required}; 
}

sub set_feeds_required
{
	my ($self,$feeds_required) = @_;
	$self->{feeds_required} = $feeds_required; 
	$self->{key_modified}{"feeds_required"} = 1; 
}

sub get_scoring_supported
{
	my ($self) = shift;
	return $self->{scoring_supported}; 
}

sub set_scoring_supported
{
	my ($self,$scoring_supported) = @_;
	$self->{scoring_supported} = $scoring_supported; 
	$self->{key_modified}{"scoring_supported"} = 1; 
}

sub get_webform_supported
{
	my ($self) = shift;
	return $self->{webform_supported}; 
}

sub set_webform_supported
{
	my ($self,$webform_supported) = @_;
	$self->{webform_supported} = $webform_supported; 
	$self->{key_modified}{"webform_supported"} = 1; 
}

sub get_arguments
{
	my ($self) = shift;
	return $self->{arguments}; 
}

sub set_arguments
{
	my ($self,$arguments) = @_;
	if(!(ref($arguments) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: arguments EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{arguments} = $arguments; 
	$self->{key_modified}{"arguments"} = 1; 
}

sub get_module_name
{
	my ($self) = shift;
	return $self->{module_name}; 
}

sub set_module_name
{
	my ($self,$module_name) = @_;
	$self->{module_name} = $module_name; 
	$self->{key_modified}{"module_name"} = 1; 
}

sub get_business_card_field_limit
{
	my ($self) = shift;
	return $self->{business_card_field_limit}; 
}

sub set_business_card_field_limit
{
	my ($self,$business_card_field_limit) = @_;
	$self->{business_card_field_limit} = $business_card_field_limit; 
	$self->{key_modified}{"business_card_field_limit"} = 1; 
}

sub get_custom_view
{
	my ($self) = shift;
	return $self->{custom_view}; 
}

sub set_custom_view
{
	my ($self,$custom_view) = @_;
	if(!(($custom_view)->isa("customviews::CustomView")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: custom_view EXPECTED TYPE: customviews::CustomView", undef, undef); 
	}
	$self->{custom_view} = $custom_view; 
	$self->{key_modified}{"custom_view"} = 1; 
}

sub get_parent_module
{
	my ($self) = shift;
	return $self->{parent_module}; 
}

sub set_parent_module
{
	my ($self,$parent_module) = @_;
	if(!(($parent_module)->isa("modules::Module")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: parent_module EXPECTED TYPE: modules::Module", undef, undef); 
	}
	$self->{parent_module} = $parent_module; 
	$self->{key_modified}{"parent_module"} = 1; 
}

sub get_territory
{
	my ($self) = shift;
	return $self->{territory}; 
}

sub set_territory
{
	my ($self,$territory) = @_;
	if(!(($territory)->isa("modules::Territory")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: territory EXPECTED TYPE: modules::Territory", undef, undef); 
	}
	$self->{territory} = $territory; 
	$self->{key_modified}{"territory"} = 1; 
}

sub is_key_modified
{
	my ($self,$key) = @_;
	if((exists($self->{key_modified}{$key})))
	{
		return $self->{key_modified}{$key}; 
	}
	return undef; 
}

sub set_key_modified
{
	my ($self,$key,$modification) = @_;
	$self->{key_modified}{$key} = $modification; 
}
1;