require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package taxes::Preference;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		auto_populate_tax => undef,
		modify_tax_rates => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_auto_populate_tax
{
	my ($self) = shift;
	return $self->{auto_populate_tax}; 
}

sub set_auto_populate_tax
{
	my ($self,$auto_populate_tax) = @_;
	$self->{auto_populate_tax} = $auto_populate_tax; 
	$self->{key_modified}{"auto_populate_tax"} = 1; 
}

sub get_modify_tax_rates
{
	my ($self) = shift;
	return $self->{modify_tax_rates}; 
}

sub set_modify_tax_rates
{
	my ($self,$modify_tax_rates) = @_;
	$self->{modify_tax_rates} = $modify_tax_rates; 
	$self->{key_modified}{"modify_tax_rates"} = 1; 
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