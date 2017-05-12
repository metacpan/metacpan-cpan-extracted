
package Xmldoom::Object::XMLGenerator;

use XML::Writer;
use XML::Writer::String;
use IO::File;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $output_fh;
	my $output_filename;
	my $output_string;

	my $expand_objects;

	if ( ref($args) eq 'HASH' )
	{
		$output_fh       = $args->{output_fh};
		$output_filename = $args->{output_filename};
		$expand_objects  = $args->{expand_objects};
	}

	if ( defined $output_filename and defined $output_fh )
	{
		die "Cannot specify both filename and a filehandle.";
	}

	if ( not defined $output_filename and not defined $output_fh )
	{
		$output_string = XML::Writer::String->new();
		$output_fh     = $output_string;
	}
	elsif ( defined $output_filename )
	{
		$output_fh = IO::File->new(">$output_filename");
	}

	my $xml_writer = XML::Writer->new(OUTPUT => $output_fh, DATA_MODE => 1);

	my $self = {
		output_filename => $output_filename,
		output_fh       => $output_fh,
		output_string   => $output_string,
		xml_writer      => $xml_writer,
		expand_objects  => $expand_objects || 0,
	};

	bless  $self, $class;
	return $self;
}

sub get_filename { return shift->{output_filename}; }
sub get_fh       { return shift->{output_fh}; }

sub get_string
{
	my $self = shift;

	if ( defined $self->{output_string} )
	{
		return $self->{output_string}->value();
	}

	return undef;
}

# for writting custom XML junk
sub startTag
{
	my $self = shift;
	$self->{xml_writer}->startTag(@_);
}

sub characters
{
	my $self = shift;
	$self->{xml_writer}->characters(@_);
}

sub endTag
{
	my $self = shift;
	$self->{xml_writer}->endTag(@_);
}

sub emptyTag
{
	my $self = shift;
	$self->{xml_writer}->emptyTag(@_);
}

# the real bleeding work
sub generate
{
	my ($self, $object, $tag_name) = @_;

	# convenience.
	my $writer = $self->{xml_writer};

	if ( not defined $tag_name )
	{
		$tag_name = $object->_get_definition()->get_name();
	}

	$writer->startTag( $tag_name, %{$object->_get_key()} );
	foreach my $prop ( @{$object->_get_properties()} )
	{
		if ( $prop->get_type() eq 'inherent' )
		{
			my $value = $prop->get();
			if ( ref($value) and $value->isa('Xmldoom::Object') )
			{
				if ( $self->{expand_objects} )
				{
					$self->generate( $value, $prop->get_name() );
				}
				else
				{
					$writer->emptyTag( $prop->get_name(), %{$value->_get_key()} );
				}
			}
			else
			{
				$writer->startTag( $prop->get_name() );
				$writer->characters( $value );
				$writer->endTag( $prop->get_name() );
			}
		}
	}
	$writer->endTag( $tag_name );
}

sub generateInternal
{
	my ($self, $object, $tag_name) = @_;

	# convenience.
	my $writer = $self->{xml_writer};

	if ( not defined $tag_name )
	{
		$tag_name = "object";
	}

	$writer->startTag( $tag_name, name => $object->_get_definition()->get_name() );

	# send the object key
	$writer->startTag( 'key' );
	while ( my ($key, $val) = each %{$object->_get_key()} )
	{
		$writer->startTag( 'value', name => $key );
		$writer->characters( $val );
		$writer->endTag( 'value' );
	}
	$writer->endTag( 'key' );

	# send the attribute values
	$writer->startTag( 'attributes' );
	while ( my ($key, $val) = each %{$object->_get_attributes()} )
	{
		$writer->startTag( 'value', name => $key );
		$writer->characters( $val );
		$writer->endTag( 'value' );
	}
	$writer->endTag( 'attributes' );

	$writer->endTag( $tag_name );
}

sub close
{
	my $self = shift;

	$self->{xml_writer}->end();

	if ( not defined $self->{output_string} )
	{
		$self->{output_fh}->close();
	}
}

1;

