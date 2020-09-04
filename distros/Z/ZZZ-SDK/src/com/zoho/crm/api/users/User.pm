require 'src/com/zoho/crm/api/profiles/Profile.pm';
require 'src/com/zoho/crm/api/roles/Role.pm';
require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package users::User;
use Moose;
our @ISA = qw (record::Record );

sub new
{
	my ($class) = shift;
	my $self = 
	{
	};
	bless $self,$class;
	return $self;
}
sub get_country
{
	my ($self) = shift;
	return $self->get_key_value("country"); 
}

sub set_country
{
	my ($self,$country) = @_;
	$self->add_key_value("country", $country); 
}

sub get_customize_info
{
	my ($self) = shift;
	return $self->get_key_value("customize_info"); 
}

sub set_customize_info
{
	my ($self,$customize_info) = @_;
	if(!(($customize_info)->isa("users::CustomizeInfo")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: customize_info EXPECTED TYPE: users::CustomizeInfo", undef, undef); 
	}
	$self->add_key_value("customize_info", $customize_info); 
}

sub get_role
{
	my ($self) = shift;
	return $self->get_key_value("role"); 
}

sub set_role
{
	my ($self,$role) = @_;
	if(!(($role)->isa("roles::Role")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: role EXPECTED TYPE: roles::Role", undef, undef); 
	}
	$self->add_key_value("role", $role); 
}

sub get_signature
{
	my ($self) = shift;
	return $self->get_key_value("signature"); 
}

sub set_signature
{
	my ($self,$signature) = @_;
	$self->add_key_value("signature", $signature); 
}

sub get_city
{
	my ($self) = shift;
	return $self->get_key_value("city"); 
}

sub set_city
{
	my ($self,$city) = @_;
	$self->add_key_value("city", $city); 
}

sub get_name_format
{
	my ($self) = shift;
	return $self->get_key_value("name_format"); 
}

sub set_name_format
{
	my ($self,$name_format) = @_;
	$self->add_key_value("name_format", $name_format); 
}

sub get_personal_account
{
	my ($self) = shift;
	return $self->get_key_value("personal_account"); 
}

sub set_personal_account
{
	my ($self,$personal_account) = @_;
	$self->add_key_value("personal_account", $personal_account); 
}

sub get_default_tab_group
{
	my ($self) = shift;
	return $self->get_key_value("default_tab_group"); 
}

sub set_default_tab_group
{
	my ($self,$default_tab_group) = @_;
	$self->add_key_value("default_tab_group", $default_tab_group); 
}

sub get_language
{
	my ($self) = shift;
	return $self->get_key_value("language"); 
}

sub set_language
{
	my ($self,$language) = @_;
	$self->add_key_value("language", $language); 
}

sub get_locale
{
	my ($self) = shift;
	return $self->get_key_value("locale"); 
}

sub set_locale
{
	my ($self,$locale) = @_;
	$self->add_key_value("locale", $locale); 
}

sub get_microsoft
{
	my ($self) = shift;
	return $self->get_key_value("microsoft"); 
}

sub set_microsoft
{
	my ($self,$microsoft) = @_;
	$self->add_key_value("microsoft", $microsoft); 
}

sub get_isonline
{
	my ($self) = shift;
	return $self->get_key_value("Isonline"); 
}

sub set_isonline
{
	my ($self,$isonline) = @_;
	$self->add_key_value("Isonline", $isonline); 
}

sub get_street
{
	my ($self) = shift;
	return $self->get_key_value("street"); 
}

sub set_street
{
	my ($self,$street) = @_;
	$self->add_key_value("street", $street); 
}

sub get_currency
{
	my ($self) = shift;
	return $self->get_key_value("Currency"); 
}

sub set_currency
{
	my ($self,$currency) = @_;
	$self->add_key_value("Currency", $currency); 
}

sub get_alias
{
	my ($self) = shift;
	return $self->get_key_value("alias"); 
}

sub set_alias
{
	my ($self,$alias) = @_;
	$self->add_key_value("alias", $alias); 
}

sub get_theme
{
	my ($self) = shift;
	return $self->get_key_value("theme"); 
}

sub set_theme
{
	my ($self,$theme) = @_;
	if(!(($theme)->isa("users::Theme")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: theme EXPECTED TYPE: users::Theme", undef, undef); 
	}
	$self->add_key_value("theme", $theme); 
}

sub get_state
{
	my ($self) = shift;
	return $self->get_key_value("state"); 
}

sub set_state
{
	my ($self,$state) = @_;
	$self->add_key_value("state", $state); 
}

sub get_fax
{
	my ($self) = shift;
	return $self->get_key_value("fax"); 
}

sub set_fax
{
	my ($self,$fax) = @_;
	$self->add_key_value("fax", $fax); 
}

sub get_country_locale
{
	my ($self) = shift;
	return $self->get_key_value("country_locale"); 
}

sub set_country_locale
{
	my ($self,$country_locale) = @_;
	$self->add_key_value("country_locale", $country_locale); 
}

sub get_first_name
{
	my ($self) = shift;
	return $self->get_key_value("first_name"); 
}

sub set_first_name
{
	my ($self,$first_name) = @_;
	$self->add_key_value("first_name", $first_name); 
}

sub get_email
{
	my ($self) = shift;
	return $self->get_key_value("email"); 
}

sub set_email
{
	my ($self,$email) = @_;
	$self->add_key_value("email", $email); 
}

sub get_reporting_to
{
	my ($self) = shift;
	return $self->get_key_value("Reporting_To"); 
}

sub set_reporting_to
{
	my ($self,$reporting_to) = @_;
	if(!(($reporting_to)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: reporting_to EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->add_key_value("Reporting_To", $reporting_to); 
}

sub get_decimal_separator
{
	my ($self) = shift;
	return $self->get_key_value("decimal_separator"); 
}

sub set_decimal_separator
{
	my ($self,$decimal_separator) = @_;
	$self->add_key_value("decimal_separator", $decimal_separator); 
}

sub get_zip
{
	my ($self) = shift;
	return $self->get_key_value("zip"); 
}

sub set_zip
{
	my ($self,$zip) = @_;
	$self->add_key_value("zip", $zip); 
}

sub get_website
{
	my ($self) = shift;
	return $self->get_key_value("website"); 
}

sub set_website
{
	my ($self,$website) = @_;
	$self->add_key_value("website", $website); 
}

sub get_time_format
{
	my ($self) = shift;
	return $self->get_key_value("time_format"); 
}

sub set_time_format
{
	my ($self,$time_format) = @_;
	$self->add_key_value("time_format", $time_format); 
}

sub get_offset
{
	my ($self) = shift;
	return $self->get_key_value("offset"); 
}

sub set_offset
{
	my ($self,$offset) = @_;
	$self->add_key_value("offset", $offset); 
}

sub get_profile
{
	my ($self) = shift;
	return $self->get_key_value("profile"); 
}

sub set_profile
{
	my ($self,$profile) = @_;
	if(!(($profile)->isa("profiles::Profile")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: profile EXPECTED TYPE: profiles::Profile", undef, undef); 
	}
	$self->add_key_value("profile", $profile); 
}

sub get_mobile
{
	my ($self) = shift;
	return $self->get_key_value("mobile"); 
}

sub set_mobile
{
	my ($self,$mobile) = @_;
	$self->add_key_value("mobile", $mobile); 
}

sub get_last_name
{
	my ($self) = shift;
	return $self->get_key_value("last_name"); 
}

sub set_last_name
{
	my ($self,$last_name) = @_;
	$self->add_key_value("last_name", $last_name); 
}

sub get_time_zone
{
	my ($self) = shift;
	return $self->get_key_value("time_zone"); 
}

sub set_time_zone
{
	my ($self,$time_zone) = @_;
	$self->add_key_value("time_zone", $time_zone); 
}

sub get_zuid
{
	my ($self) = shift;
	return $self->get_key_value("zuid"); 
}

sub set_zuid
{
	my ($self,$zuid) = @_;
	$self->add_key_value("zuid", $zuid); 
}

sub get_confirm
{
	my ($self) = shift;
	return $self->get_key_value("confirm"); 
}

sub set_confirm
{
	my ($self,$confirm) = @_;
	$self->add_key_value("confirm", $confirm); 
}

sub get_full_name
{
	my ($self) = shift;
	return $self->get_key_value("full_name"); 
}

sub set_full_name
{
	my ($self,$full_name) = @_;
	$self->add_key_value("full_name", $full_name); 
}

sub get_territories
{
	my ($self) = shift;
	return $self->get_key_value("territories"); 
}

sub set_territories
{
	my ($self,$territories) = @_;
	if(!(ref($territories) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: territories EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->add_key_value("territories", $territories); 
}

sub get_phone
{
	my ($self) = shift;
	return $self->get_key_value("phone"); 
}

sub set_phone
{
	my ($self,$phone) = @_;
	$self->add_key_value("phone", $phone); 
}

sub get_dob
{
	my ($self) = shift;
	return $self->get_key_value("dob"); 
}

sub set_dob
{
	my ($self,$dob) = @_;
	$self->add_key_value("dob", $dob); 
}

sub get_date_format
{
	my ($self) = shift;
	return $self->get_key_value("date_format"); 
}

sub set_date_format
{
	my ($self,$date_format) = @_;
	$self->add_key_value("date_format", $date_format); 
}

sub get_status
{
	my ($self) = shift;
	return $self->get_key_value("status"); 
}

sub set_status
{
	my ($self,$status) = @_;
	$self->add_key_value("status", $status); 
}

sub get_name
{
	my ($self) = shift;
	return $self->get_key_value("name"); 
}

sub set_name
{
	my ($self,$name) = @_;
	$self->add_key_value("name", $name); 
}
1;