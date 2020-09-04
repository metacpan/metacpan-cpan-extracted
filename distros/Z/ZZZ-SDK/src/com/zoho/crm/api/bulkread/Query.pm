require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package bulkread::Query;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		module => undef,
		cvid => undef,
		fields => undef,
		page => undef,
		criteria => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_module
{
	my ($self) = shift;
	return $self->{module}; 
}

sub set_module
{
	my ($self,$module) = @_;
	$self->{module} = $module; 
	$self->{key_modified}{"module"} = 1; 
}

sub get_cvid
{
	my ($self) = shift;
	return $self->{cvid}; 
}

sub set_cvid
{
	my ($self,$cvid) = @_;
	$self->{cvid} = $cvid; 
	$self->{key_modified}{"cvid"} = 1; 
}

sub get_fields
{
	my ($self) = shift;
	return $self->{fields}; 
}

sub set_fields
{
	my ($self,$fields) = @_;
	if(!(ref($fields) eq "ARRAY"))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: fields EXPECTED TYPE: ARRAY", undef, undef); 
	}
	$self->{fields} = $fields; 
	$self->{key_modified}{"fields"} = 1; 
}

sub get_page
{
	my ($self) = shift;
	return $self->{page}; 
}

sub set_page
{
	my ($self,$page) = @_;
	$self->{page} = $page; 
	$self->{key_modified}{"page"} = 1; 
}

sub get_criteria
{
	my ($self) = shift;
	return $self->{criteria}; 
}

sub set_criteria
{
	my ($self,$criteria) = @_;
	if(!(($criteria)->isa("bulkread::Criteria")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: criteria EXPECTED TYPE: bulkread::Criteria", undef, undef); 
	}
	$self->{criteria} = $criteria; 
	$self->{key_modified}{"criteria"} = 1; 
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