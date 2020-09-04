require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::LeadConverter;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		overwrite => undef,
		notify_lead_owner => undef,
		notify_new_entity_owner => undef,
		accounts => undef,
		contacts => undef,
		assign_to => undef,
		deals => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_overwrite
{
	my ($self) = shift;
	return $self->{overwrite}; 
}

sub set_overwrite
{
	my ($self,$overwrite) = @_;
	$self->{overwrite} = $overwrite; 
	$self->{key_modified}{"overwrite"} = 1; 
}

sub get_notify_lead_owner
{
	my ($self) = shift;
	return $self->{notify_lead_owner}; 
}

sub set_notify_lead_owner
{
	my ($self,$notify_lead_owner) = @_;
	$self->{notify_lead_owner} = $notify_lead_owner; 
	$self->{key_modified}{"notify_lead_owner"} = 1; 
}

sub get_notify_new_entity_owner
{
	my ($self) = shift;
	return $self->{notify_new_entity_owner}; 
}

sub set_notify_new_entity_owner
{
	my ($self,$notify_new_entity_owner) = @_;
	$self->{notify_new_entity_owner} = $notify_new_entity_owner; 
	$self->{key_modified}{"notify_new_entity_owner"} = 1; 
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

sub get_assign_to
{
	my ($self) = shift;
	return $self->{assign_to}; 
}

sub set_assign_to
{
	my ($self,$assign_to) = @_;
	$self->{assign_to} = $assign_to; 
	$self->{key_modified}{"assign_to"} = 1; 
}

sub get_deals
{
	my ($self) = shift;
	return $self->{deals}; 
}

sub set_deals
{
	my ($self,$deals) = @_;
	if(!(($deals)->isa("record::Record")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: deals EXPECTED TYPE: record::Record", undef, undef); 
	}
	$self->{deals} = $deals; 
	$self->{key_modified}{"Deals"} = 1; 
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