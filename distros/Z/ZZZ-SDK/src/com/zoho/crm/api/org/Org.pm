require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package org::Org;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		country => undef,
		photo_id => undef,
		city => undef,
		description => undef,
		mc_status => undef,
		gapps_enabled => undef,
		domain_name => undef,
		translation_enabled => undef,
		street => undef,
		alias => undef,
		currency => undef,
		id => undef,
		state => undef,
		fax => undef,
		employee_count => undef,
		zip => undef,
		website => undef,
		currency_symbol => undef,
		mobile => undef,
		currency_locale => undef,
		primary_zuid => undef,
		zia_portal_id => undef,
		time_zone => undef,
		zgid => undef,
		country_code => undef,
		license_details => undef,
		phone => undef,
		company_name => undef,
		privacy_settings => undef,
		primary_email => undef,
		iso_code => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_country
{
	my ($self) = shift;
	return $self->{country}; 
}

sub set_country
{
	my ($self,$country) = @_;
	$self->{country} = $country; 
	$self->{key_modified}{"country"} = 1; 
}

sub get_photo_id
{
	my ($self) = shift;
	return $self->{photo_id}; 
}

sub set_photo_id
{
	my ($self,$photo_id) = @_;
	$self->{photo_id} = $photo_id; 
	$self->{key_modified}{"photo_id"} = 1; 
}

sub get_city
{
	my ($self) = shift;
	return $self->{city}; 
}

sub set_city
{
	my ($self,$city) = @_;
	$self->{city} = $city; 
	$self->{key_modified}{"city"} = 1; 
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

sub get_mc_status
{
	my ($self) = shift;
	return $self->{mc_status}; 
}

sub set_mc_status
{
	my ($self,$mc_status) = @_;
	$self->{mc_status} = $mc_status; 
	$self->{key_modified}{"mc_status"} = 1; 
}

sub get_gapps_enabled
{
	my ($self) = shift;
	return $self->{gapps_enabled}; 
}

sub set_gapps_enabled
{
	my ($self,$gapps_enabled) = @_;
	$self->{gapps_enabled} = $gapps_enabled; 
	$self->{key_modified}{"gapps_enabled"} = 1; 
}

sub get_domain_name
{
	my ($self) = shift;
	return $self->{domain_name}; 
}

sub set_domain_name
{
	my ($self,$domain_name) = @_;
	$self->{domain_name} = $domain_name; 
	$self->{key_modified}{"domain_name"} = 1; 
}

sub get_translation_enabled
{
	my ($self) = shift;
	return $self->{translation_enabled}; 
}

sub set_translation_enabled
{
	my ($self,$translation_enabled) = @_;
	$self->{translation_enabled} = $translation_enabled; 
	$self->{key_modified}{"translation_enabled"} = 1; 
}

sub get_street
{
	my ($self) = shift;
	return $self->{street}; 
}

sub set_street
{
	my ($self,$street) = @_;
	$self->{street} = $street; 
	$self->{key_modified}{"street"} = 1; 
}

sub get_alias
{
	my ($self) = shift;
	return $self->{alias}; 
}

sub set_alias
{
	my ($self,$alias) = @_;
	$self->{alias} = $alias; 
	$self->{key_modified}{"alias"} = 1; 
}

sub get_currency
{
	my ($self) = shift;
	return $self->{currency}; 
}

sub set_currency
{
	my ($self,$currency) = @_;
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

sub get_state
{
	my ($self) = shift;
	return $self->{state}; 
}

sub set_state
{
	my ($self,$state) = @_;
	$self->{state} = $state; 
	$self->{key_modified}{"state"} = 1; 
}

sub get_fax
{
	my ($self) = shift;
	return $self->{fax}; 
}

sub set_fax
{
	my ($self,$fax) = @_;
	$self->{fax} = $fax; 
	$self->{key_modified}{"fax"} = 1; 
}

sub get_employee_count
{
	my ($self) = shift;
	return $self->{employee_count}; 
}

sub set_employee_count
{
	my ($self,$employee_count) = @_;
	$self->{employee_count} = $employee_count; 
	$self->{key_modified}{"employee_count"} = 1; 
}

sub get_zip
{
	my ($self) = shift;
	return $self->{zip}; 
}

sub set_zip
{
	my ($self,$zip) = @_;
	$self->{zip} = $zip; 
	$self->{key_modified}{"zip"} = 1; 
}

sub get_website
{
	my ($self) = shift;
	return $self->{website}; 
}

sub set_website
{
	my ($self,$website) = @_;
	$self->{website} = $website; 
	$self->{key_modified}{"website"} = 1; 
}

sub get_currency_symbol
{
	my ($self) = shift;
	return $self->{currency_symbol}; 
}

sub set_currency_symbol
{
	my ($self,$currency_symbol) = @_;
	$self->{currency_symbol} = $currency_symbol; 
	$self->{key_modified}{"currency_symbol"} = 1; 
}

sub get_mobile
{
	my ($self) = shift;
	return $self->{mobile}; 
}

sub set_mobile
{
	my ($self,$mobile) = @_;
	$self->{mobile} = $mobile; 
	$self->{key_modified}{"mobile"} = 1; 
}

sub get_currency_locale
{
	my ($self) = shift;
	return $self->{currency_locale}; 
}

sub set_currency_locale
{
	my ($self,$currency_locale) = @_;
	$self->{currency_locale} = $currency_locale; 
	$self->{key_modified}{"currency_locale"} = 1; 
}

sub get_primary_zuid
{
	my ($self) = shift;
	return $self->{primary_zuid}; 
}

sub set_primary_zuid
{
	my ($self,$primary_zuid) = @_;
	$self->{primary_zuid} = $primary_zuid; 
	$self->{key_modified}{"primary_zuid"} = 1; 
}

sub get_zia_portal_id
{
	my ($self) = shift;
	return $self->{zia_portal_id}; 
}

sub set_zia_portal_id
{
	my ($self,$zia_portal_id) = @_;
	$self->{zia_portal_id} = $zia_portal_id; 
	$self->{key_modified}{"zia_portal_id"} = 1; 
}

sub get_time_zone
{
	my ($self) = shift;
	return $self->{time_zone}; 
}

sub set_time_zone
{
	my ($self,$time_zone) = @_;
	$self->{time_zone} = $time_zone; 
	$self->{key_modified}{"time_zone"} = 1; 
}

sub get_zgid
{
	my ($self) = shift;
	return $self->{zgid}; 
}

sub set_zgid
{
	my ($self,$zgid) = @_;
	$self->{zgid} = $zgid; 
	$self->{key_modified}{"zgid"} = 1; 
}

sub get_country_code
{
	my ($self) = shift;
	return $self->{country_code}; 
}

sub set_country_code
{
	my ($self,$country_code) = @_;
	$self->{country_code} = $country_code; 
	$self->{key_modified}{"country_code"} = 1; 
}

sub get_license_details
{
	my ($self) = shift;
	return $self->{license_details}; 
}

sub set_license_details
{
	my ($self,$license_details) = @_;
	if(!(($license_details)->isa("org::LicenseDetails")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: license_details EXPECTED TYPE: org::LicenseDetails", undef, undef); 
	}
	$self->{license_details} = $license_details; 
	$self->{key_modified}{"license_details"} = 1; 
}

sub get_phone
{
	my ($self) = shift;
	return $self->{phone}; 
}

sub set_phone
{
	my ($self,$phone) = @_;
	$self->{phone} = $phone; 
	$self->{key_modified}{"phone"} = 1; 
}

sub get_company_name
{
	my ($self) = shift;
	return $self->{company_name}; 
}

sub set_company_name
{
	my ($self,$company_name) = @_;
	$self->{company_name} = $company_name; 
	$self->{key_modified}{"company_name"} = 1; 
}

sub get_privacy_settings
{
	my ($self) = shift;
	return $self->{privacy_settings}; 
}

sub set_privacy_settings
{
	my ($self,$privacy_settings) = @_;
	$self->{privacy_settings} = $privacy_settings; 
	$self->{key_modified}{"privacy_settings"} = 1; 
}

sub get_primary_email
{
	my ($self) = shift;
	return $self->{primary_email}; 
}

sub set_primary_email
{
	my ($self,$primary_email) = @_;
	$self->{primary_email} = $primary_email; 
	$self->{key_modified}{"primary_email"} = 1; 
}

sub get_iso_code
{
	my ($self) = shift;
	return $self->{iso_code}; 
}

sub set_iso_code
{
	my ($self,$iso_code) = @_;
	$self->{iso_code} = $iso_code; 
	$self->{key_modified}{"iso_code"} = 1; 
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