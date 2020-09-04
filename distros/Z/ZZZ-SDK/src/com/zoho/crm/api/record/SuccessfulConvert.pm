require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::SuccessfulConvert;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		contacts => undef,
		deals => undef,
		accounts => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_contacts
{
	my ($self) = shift;
	return $self->{contacts}; 
}

sub set_contacts
{
	my ($self,$contacts) = @_;
	$self->{contacts} = $contacts; 
	$self->{key_modified}{"Contacts"} = 1; 
}

sub get_deals
{
	my ($self) = shift;
	return $self->{deals}; 
}

sub set_deals
{
	my ($self,$deals) = @_;
	$self->{deals} = $deals; 
	$self->{key_modified}{"Deals"} = 1; 
}

sub get_accounts
{
	my ($self) = shift;
	return $self->{accounts}; 
}

sub set_accounts
{
	my ($self,$accounts) = @_;
	$self->{accounts} = $accounts; 
	$self->{key_modified}{"Accounts"} = 1; 
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