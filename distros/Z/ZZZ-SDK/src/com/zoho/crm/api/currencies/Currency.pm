require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package currencies::Currency;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
		symbol => undef,
		created_time => undef,
		is_active => undef,
		exchange_rate => undef,
		format => undef,
		created_by => undef,
		prefix_symbol => undef,
		is_base => undef,
		modified_time => undef,
		name => undef,
		modified_by => undef,
		id => undef,
		iso_code => undef,
		key_modified => (),
	};
	bless $self,$class;
	return $self;
}
sub get_symbol
{
	my ($self) = shift;
	return $self->{symbol}; 
}

sub set_symbol
{
	my ($self,$symbol) = @_;
	$self->{symbol} = $symbol; 
	$self->{key_modified}{"symbol"} = 1; 
}

sub get_created_time
{
	my ($self) = shift;
	return $self->{created_time}; 
}

sub set_created_time
{
	my ($self,$created_time) = @_;
	if(!(($created_time)->isa("DateTime")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_time EXPECTED TYPE: DateTime", undef, undef); 
	}
	$self->{created_time} = $created_time; 
	$self->{key_modified}{"created_time"} = 1; 
}

sub get_is_active
{
	my ($self) = shift;
	return $self->{is_active}; 
}

sub set_is_active
{
	my ($self,$is_active) = @_;
	$self->{is_active} = $is_active; 
	$self->{key_modified}{"is_active"} = 1; 
}

sub get_exchange_rate
{
	my ($self) = shift;
	return $self->{exchange_rate}; 
}

sub set_exchange_rate
{
	my ($self,$exchange_rate) = @_;
	$self->{exchange_rate} = $exchange_rate; 
	$self->{key_modified}{"exchange_rate"} = 1; 
}

sub get_format
{
	my ($self) = shift;
	return $self->{format}; 
}

sub set_format
{
	my ($self,$format) = @_;
	if(!(($format)->isa("currencies::Format")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: format EXPECTED TYPE: currencies::Format", undef, undef); 
	}
	$self->{format} = $format; 
	$self->{key_modified}{"format"} = 1; 
}

sub get_created_by
{
	my ($self) = shift;
	return $self->{created_by}; 
}

sub set_created_by
{
	my ($self,$created_by) = @_;
	if(!(($created_by)->isa("users::User")))
	{
		die SDKException->new($Constants::DATA_TYPE_ERROR, "KEY: created_by EXPECTED TYPE: users::User", undef, undef); 
	}
	$self->{created_by} = $created_by; 
	$self->{key_modified}{"created_by"} = 1; 
}

sub get_prefix_symbol
{
	my ($self) = shift;
	return $self->{prefix_symbol}; 
}

sub set_prefix_symbol
{
	my ($self,$prefix_symbol) = @_;
	$self->{prefix_symbol} = $prefix_symbol; 
	$self->{key_modified}{"prefix_symbol"} = 1; 
}

sub get_is_base
{
	my ($self) = shift;
	return $self->{is_base}; 
}

sub set_is_base
{
	my ($self,$is_base) = @_;
	$self->{is_base} = $is_base; 
	$self->{key_modified}{"is_base"} = 1; 
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