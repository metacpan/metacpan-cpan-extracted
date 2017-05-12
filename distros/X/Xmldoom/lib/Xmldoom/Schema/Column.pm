
package Xmldoom::Schema::Column;

use Xmldoom::Threads;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $name;
	my $required;
	my $primary_key;
	my $id_generator;
	my $type;
	my $description;
	my $size;
	my $options;
	my $auto_increment;
	my $default;
	my $timestamp;

	if ( ref($args) eq 'HASH' )
	{
		$parent         = $args->{parent};
		$name           = $args->{name};
		$type           = $args->{type};
		$size           = $args->{size};
		$options        = $args->{options};
		$required       = $args->{required};
		$primary_key    = $args->{primary_key};
		$id_generator   = $args->{id_generator};
		$description    = $args->{description};
		$auto_increment = $args->{auto_increment};
		$default        = $args->{default};
		$timestamp      = $args->{timestamp};
	}
	else
	{
		$parent      = $args;
		$name        = shift;
		$type        = shift;
		$size        = shift;
		$required    = shift;
		$primary_key = shift;
		$description = shift;
	}

	if ( not defined $name or not defined $type )
	{
		die "Cannot create a column without setting both name and type";
	}

	my $self = {
		parent         => $parent,
		name           => $name,
		type           => uc($type),
		size           => $size,
		options        => $options,
		required       => $required       || 0,
		primary_key    => $primary_key    || 0,
		auto_increment => $auto_increment || 0,
		id_generator   => $id_generator,
		description    => $description,
		default        => $default,
		timestamp      => $timestamp || 0,
	};

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $args->{shared});
}

sub DESTROY
{
	my $self = shift;

	# we don't need no stinking weak references!
	$self->{parent} = undef;
}

sub get_table         { return shift->{parent}; }
sub get_name          { return shift->{name}; }
sub get_type          { return shift->{type}; }
sub get_size          { return shift->{size}; }
sub get_options       { return shift->{options}; }
sub get_description   { return shift->{description}; }
sub get_default       { return shift->{default}; }
sub get_timestamp     { return shift->{timestamp}; }
sub get_id_generator  { return shift->{id_generator}; }
sub is_primary_key    { return shift->{primary_key}; }
sub is_required       { return shift->{required}; }
sub is_auto_increment { return shift->{auto_increment}; }

sub get_data_type
{
	my $self = shift;

	my $value = { };

	if ( $self->{type} =~ /char|text/i )
	{
		$value->{type} = "string";
		$value->{size} = $self->{size};
	}
	elsif ( $self->{type} =~ /enum/i )
	{
		$value->{type}    = "string";
		$value->{options} = $self->{options};
	}
	elsif ( $self->{type} =~ /int/i )
	{
		$value->{type} = "integer";
	}
	elsif ( $self->{type} =~ /float/i )
	{
		$value->{type} = "float";
	}
	elsif ( $self->{type} =~ /date|time/i )
	{
		$value->{type} = "date";
	}

	return $value;
}

1;

