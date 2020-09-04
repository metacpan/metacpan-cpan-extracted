require 'src/com/zoho/crm/api/customviews/Criteria.pm';
require 'src/com/zoho/crm/api/layouts/Layout.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package fields::Field;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		system_mandatory => undef,
		webhook => undef,
		layouts => undef,
		content => undef,
		column_name => undef,
		type => undef,
		transition_sequence => undef,
		personality_name => undef,
		message => undef,
		mandatory => undef,
		criteria => undef,
		related_details => undef,
		json_type => undef,
		crypt => undef,
		field_label => undef,
		tooltip => undef,
		created_source => undef,
		field_read_only => undef,
		display_label => undef,
		read_only => undef,
		association_details => undef,
		quick_sequence_number => undef,
		businesscard_supported => undef,
		multi_module_lookup => undef,
		currency => undef,
		id => undef,
		custom_field => undef,
		lookup => undef,
		visible => undef,
		length => undef,
		view_type => undef,
		subform => undef,
		api_name => undef,
		unique => undef,
		history_tracking => undef,
		data_type => undef,
		formula => undef,
		decimal_place => undef,
		mass_update => undef,
		blueprint_supported => undef,
		multiselectlookup => undef,
		pick_list_values => undef,
		auto_number => undef,
		default_value => undef,
		section_id => undef,
		validation_rule => undef,
		convert_mapping => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_system_mandatory
{
	my ($self) = shift;
	return $self->{system_mandatory}; 
}

sub set_system_mandatory
{
	my ($self,$system_mandatory) = @_;
	$self->{system_mandatory} = $system_mandatory; 
	$self->{key_modified}{"system_mandatory"} = 1; 
}

sub get_webhook
{
	my ($self) = shift;
	return $self->{webhook}; 
}

sub set_webhook
{
	my ($self,$webhook) = @_;
	$self->{webhook} = $webhook; 
	$self->{key_modified}{"webhook"} = 1; 
}

sub get_layouts
{
	my ($self) = shift;
	return $self->{layouts}; 
}

sub set_layouts
{
	my ($self,$layouts) = @_;
	if(!(($layouts)->isa("layouts::Layout")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: layouts EXPECTED TYPE: layouts::Layout", undef, undef); 
	}
	$self->{layouts} = $layouts; 
	$self->{key_modified}{"layouts"} = 1; 
}

sub get_content
{
	my ($self) = shift;
	return $self->{content}; 
}

sub set_content
{
	my ($self,$content) = @_;
	$self->{content} = $content; 
	$self->{key_modified}{"content"} = 1; 
}

sub get_column_name
{
	my ($self) = shift;
	return $self->{column_name}; 
}

sub set_column_name
{
	my ($self,$column_name) = @_;
	$self->{column_name} = $column_name; 
	$self->{key_modified}{"column_name"} = 1; 
}

sub get_type
{
	my ($self) = shift;
	return $self->{type}; 
}

sub set_type
{
	my ($self,$type) = @_;
	$self->{type} = $type; 
	$self->{key_modified}{"_type"} = 1; 
}

sub get_transition_sequence
{
	my ($self) = shift;
	return $self->{transition_sequence}; 
}

sub set_transition_sequence
{
	my ($self,$transition_sequence) = @_;
	$self->{transition_sequence} = $transition_sequence; 
	$self->{key_modified}{"transition_sequence"} = 1; 
}

sub get_personality_name
{
	my ($self) = shift;
	return $self->{personality_name}; 
}

sub set_personality_name
{
	my ($self,$personality_name) = @_;
	$self->{personality_name} = $personality_name; 
	$self->{key_modified}{"personality_name"} = 1; 
}

sub get_message
{
	my ($self) = shift;
	return $self->{message}; 
}

sub set_message
{
	my ($self,$message) = @_;
	$self->{message} = $message; 
	$self->{key_modified}{"message"} = 1; 
}

sub get_mandatory
{
	my ($self) = shift;
	return $self->{mandatory}; 
}

sub set_mandatory
{
	my ($self,$mandatory) = @_;
	$self->{mandatory} = $mandatory; 
	$self->{key_modified}{"mandatory"} = 1; 
}

sub get_criteria
{
	my ($self) = shift;
	return $self->{criteria}; 
}

sub set_criteria
{
	my ($self,$criteria) = @_;
	if(!(($criteria)->isa("customviews::Criteria")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: criteria EXPECTED TYPE: customviews::Criteria", undef, undef); 
	}
	$self->{criteria} = $criteria; 
	$self->{key_modified}{"criteria"} = 1; 
}

sub get_related_details
{
	my ($self) = shift;
	return $self->{related_details}; 
}

sub set_related_details
{
	my ($self,$related_details) = @_;
	if(!(($related_details)->isa("fields::RelatedDetails")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: related_details EXPECTED TYPE: fields::RelatedDetails", undef, undef); 
	}
	$self->{related_details} = $related_details; 
	$self->{key_modified}{"related_details"} = 1; 
}

sub get_json_type
{
	my ($self) = shift;
	return $self->{json_type}; 
}

sub set_json_type
{
	my ($self,$json_type) = @_;
	$self->{json_type} = $json_type; 
	$self->{key_modified}{"json_type"} = 1; 
}

sub get_crypt
{
	my ($self) = shift;
	return $self->{crypt}; 
}

sub set_crypt
{
	my ($self,$crypt) = @_;
	if(!(($crypt)->isa("fields::Crypt")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: crypt EXPECTED TYPE: fields::Crypt", undef, undef); 
	}
	$self->{crypt} = $crypt; 
	$self->{key_modified}{"crypt"} = 1; 
}

sub get_field_label
{
	my ($self) = shift;
	return $self->{field_label}; 
}

sub set_field_label
{
	my ($self,$field_label) = @_;
	$self->{field_label} = $field_label; 
	$self->{key_modified}{"field_label"} = 1; 
}

sub get_tooltip
{
	my ($self) = shift;
	return $self->{tooltip}; 
}

sub set_tooltip
{
	my ($self,$tooltip) = @_;
	if(!(($tooltip)->isa("fields::ToolTip")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: tooltip EXPECTED TYPE: fields::ToolTip", undef, undef); 
	}
	$self->{tooltip} = $tooltip; 
	$self->{key_modified}{"tooltip"} = 1; 
}

sub get_created_source
{
	my ($self) = shift;
	return $self->{created_source}; 
}

sub set_created_source
{
	my ($self,$created_source) = @_;
	$self->{created_source} = $created_source; 
	$self->{key_modified}{"created_source"} = 1; 
}

sub get_field_read_only
{
	my ($self) = shift;
	return $self->{field_read_only}; 
}

sub set_field_read_only
{
	my ($self,$field_read_only) = @_;
	$self->{field_read_only} = $field_read_only; 
	$self->{key_modified}{"field_read_only"} = 1; 
}

sub get_display_label
{
	my ($self) = shift;
	return $self->{display_label}; 
}

sub set_display_label
{
	my ($self,$display_label) = @_;
	$self->{display_label} = $display_label; 
	$self->{key_modified}{"display_label"} = 1; 
}

sub get_read_only
{
	my ($self) = shift;
	return $self->{read_only}; 
}

sub set_read_only
{
	my ($self,$read_only) = @_;
	$self->{read_only} = $read_only; 
	$self->{key_modified}{"read_only"} = 1; 
}

sub get_association_details
{
	my ($self) = shift;
	return $self->{association_details}; 
}

sub set_association_details
{
	my ($self,$association_details) = @_;
	if(!(($association_details)->isa("fields::AssociationDetails")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: association_details EXPECTED TYPE: fields::AssociationDetails", undef, undef); 
	}
	$self->{association_details} = $association_details; 
	$self->{key_modified}{"association_details"} = 1; 
}

sub get_quick_sequence_number
{
	my ($self) = shift;
	return $self->{quick_sequence_number}; 
}

sub set_quick_sequence_number
{
	my ($self,$quick_sequence_number) = @_;
	$self->{quick_sequence_number} = $quick_sequence_number; 
	$self->{key_modified}{"quick_sequence_number"} = 1; 
}

sub get_businesscard_supported
{
	my ($self) = shift;
	return $self->{businesscard_supported}; 
}

sub set_businesscard_supported
{
	my ($self,$businesscard_supported) = @_;
	$self->{businesscard_supported} = $businesscard_supported; 
	$self->{key_modified}{"businesscard_supported"} = 1; 
}

sub get_multi_module_lookup
{
	my ($self) = shift;
	return $self->{multi_module_lookup}; 
}

sub set_multi_module_lookup
{
	my ($self,$multi_module_lookup) = @_;
	if(!(ref($multi_module_lookup) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: multi_module_lookup EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{multi_module_lookup} = $multi_module_lookup; 
	$self->{key_modified}{"multi_module_lookup"} = 1; 
}

sub get_currency
{
	my ($self) = shift;
	return $self->{currency}; 
}

sub set_currency
{
	my ($self,$currency) = @_;
	if(!(($currency)->isa("fields::Currency")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: currency EXPECTED TYPE: fields::Currency", undef, undef); 
	}
	$self->{currency} = $currency; 
	$self->{key_modified}{"currency"} = 1; 
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

sub get_custom_field
{
	my ($self) = shift;
	return $self->{custom_field}; 
}

sub set_custom_field
{
	my ($self,$custom_field) = @_;
	$self->{custom_field} = $custom_field; 
	$self->{key_modified}{"custom_field"} = 1; 
}

sub get_lookup
{
	my ($self) = shift;
	return $self->{lookup}; 
}

sub set_lookup
{
	my ($self,$lookup) = @_;
	if(!(($lookup)->isa("fields::Module")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: lookup EXPECTED TYPE: fields::Module", undef, undef); 
	}
	$self->{lookup} = $lookup; 
	$self->{key_modified}{"lookup"} = 1; 
}

sub get_visible
{
	my ($self) = shift;
	return $self->{visible}; 
}

sub set_visible
{
	my ($self,$visible) = @_;
	$self->{visible} = $visible; 
	$self->{key_modified}{"visible"} = 1; 
}

sub get_length
{
	my ($self) = shift;
	return $self->{length}; 
}

sub set_length
{
	my ($self,$length) = @_;
	$self->{length} = $length; 
	$self->{key_modified}{"length"} = 1; 
}

sub get_view_type
{
	my ($self) = shift;
	return $self->{view_type}; 
}

sub set_view_type
{
	my ($self,$view_type) = @_;
	if(!(($view_type)->isa("fields::ViewType")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: view_type EXPECTED TYPE: fields::ViewType", undef, undef); 
	}
	$self->{view_type} = $view_type; 
	$self->{key_modified}{"view_type"} = 1; 
}

sub get_subform
{
	my ($self) = shift;
	return $self->{subform}; 
}

sub set_subform
{
	my ($self,$subform) = @_;
	if(!(($subform)->isa("fields::Module")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: subform EXPECTED TYPE: fields::Module", undef, undef); 
	}
	$self->{subform} = $subform; 
	$self->{key_modified}{"subform"} = 1; 
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

sub get_unique
{
	my ($self) = shift;
	return $self->{unique}; 
}

sub set_unique
{
	my ($self,$unique) = @_;
	if(!(($unique)->isa("fields::Unique")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: unique EXPECTED TYPE: fields::Unique", undef, undef); 
	}
	$self->{unique} = $unique; 
	$self->{key_modified}{"unique"} = 1; 
}

sub get_history_tracking
{
	my ($self) = shift;
	return $self->{history_tracking}; 
}

sub set_history_tracking
{
	my ($self,$history_tracking) = @_;
	$self->{history_tracking} = $history_tracking; 
	$self->{key_modified}{"history_tracking"} = 1; 
}

sub get_data_type
{
	my ($self) = shift;
	return $self->{data_type}; 
}

sub set_data_type
{
	my ($self,$data_type) = @_;
	$self->{data_type} = $data_type; 
	$self->{key_modified}{"data_type"} = 1; 
}

sub get_formula
{
	my ($self) = shift;
	return $self->{formula}; 
}

sub set_formula
{
	my ($self,$formula) = @_;
	if(!(($formula)->isa("fields::Formula")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: formula EXPECTED TYPE: fields::Formula", undef, undef); 
	}
	$self->{formula} = $formula; 
	$self->{key_modified}{"formula"} = 1; 
}

sub get_decimal_place
{
	my ($self) = shift;
	return $self->{decimal_place}; 
}

sub set_decimal_place
{
	my ($self,$decimal_place) = @_;
	$self->{decimal_place} = $decimal_place; 
	$self->{key_modified}{"decimal_place"} = 1; 
}

sub get_mass_update
{
	my ($self) = shift;
	return $self->{mass_update}; 
}

sub set_mass_update
{
	my ($self,$mass_update) = @_;
	$self->{mass_update} = $mass_update; 
	$self->{key_modified}{"mass_update"} = 1; 
}

sub get_blueprint_supported
{
	my ($self) = shift;
	return $self->{blueprint_supported}; 
}

sub set_blueprint_supported
{
	my ($self,$blueprint_supported) = @_;
	$self->{blueprint_supported} = $blueprint_supported; 
	$self->{key_modified}{"blueprint_supported"} = 1; 
}

sub get_multiselectlookup
{
	my ($self) = shift;
	return $self->{multiselectlookup}; 
}

sub set_multiselectlookup
{
	my ($self,$multiselectlookup) = @_;
	if(!(($multiselectlookup)->isa("fields::MultiSelectLookup")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: multiselectlookup EXPECTED TYPE: fields::MultiSelectLookup", undef, undef); 
	}
	$self->{multiselectlookup} = $multiselectlookup; 
	$self->{key_modified}{"multiselectlookup"} = 1; 
}

sub get_pick_list_values
{
	my ($self) = shift;
	return $self->{pick_list_values}; 
}

sub set_pick_list_values
{
	my ($self,$pick_list_values) = @_;
	if(!(ref($pick_list_values) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: pick_list_values EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{pick_list_values} = $pick_list_values; 
	$self->{key_modified}{"pick_list_values"} = 1; 
}

sub get_auto_number
{
	my ($self) = shift;
	return $self->{auto_number}; 
}

sub set_auto_number
{
	my ($self,$auto_number) = @_;
	if(!(($auto_number)->isa("fields::AutoNumber")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: auto_number EXPECTED TYPE: fields::AutoNumber", undef, undef); 
	}
	$self->{auto_number} = $auto_number; 
	$self->{key_modified}{"auto_number"} = 1; 
}

sub get_default_value
{
	my ($self) = shift;
	return $self->{default_value}; 
}

sub set_default_value
{
	my ($self,$default_value) = @_;
	$self->{default_value} = $default_value; 
	$self->{key_modified}{"default_value"} = 1; 
}

sub get_section_id
{
	my ($self) = shift;
	return $self->{section_id}; 
}

sub set_section_id
{
	my ($self,$section_id) = @_;
	$self->{section_id} = $section_id; 
	$self->{key_modified}{"section_id"} = 1; 
}

sub get_validation_rule
{
	my ($self) = shift;
	return $self->{validation_rule}; 
}

sub set_validation_rule
{
	my ($self,$validation_rule) = @_;
	if(!(ref($validation_rule) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: validation_rule EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{validation_rule} = $validation_rule; 
	$self->{key_modified}{"validation_rule"} = 1; 
}

sub get_convert_mapping
{
	my ($self) = shift;
	return $self->{convert_mapping}; 
}

sub set_convert_mapping
{
	my ($self,$convert_mapping) = @_;
	if(!(ref($convert_mapping) eq "HASH"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: convert_mapping EXPECTED TYPE: HASH", undef, undef); 
	}
	$self->{convert_mapping} = $convert_mapping; 
	$self->{key_modified}{"convert_mapping"} = 1; 
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