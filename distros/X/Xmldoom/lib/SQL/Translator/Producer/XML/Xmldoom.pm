
package SQL::Translator::Producer::XML::Xmldoom;

use XML::Writer;
use XML::Writer::String;
use strict;

our $XMLDOOM_NS      = "http://gna.org/projects/xmldoom/database";
our $XMLDOOM_PERL_NS = "http://gna.org/projects/xmldoom/database-perl";

sub produce
{
	my ($translator, $data) = @_;

	my $schema        = $translator->schema;
	my $producer_args = $translator->producer_args;

	my $compat = 0;
	if ( $producer_args->{propel_compatible} or $producer_args->{torque_compatible} )
	{
		$compat = 1;
	}

	my $prefix_map;
	if ( not $compat )
	{
		$prefix_map = {
			$XMLDOOM_NS      => '',
			$XMLDOOM_PERL_NS => 'perl'
		};
	}

	my $str = XML::Writer::String->new();
	my $xml = XML::Writer->new(
		OUTPUT     => $str,
		DATA_MODE  => 1,
		NAMESPACES => 1,
		PREFIX_MAP => $prefix_map
	);
	my $args;

	$xml->xmlDecl('utf-8');

	$args = { };
	if ( $schema->name )
	{
		$args->{name} = $schema->name;
	}
	if ( $schema->extra( 'defaultIdMethod' ) )
	{
		$args->{defaultIdMethod} = $schema->extra( 'defaultIdMethod' );
	}
	if ( $compat )
	{
		$xml->startTag('database', %$args);
	}
	else
	{
		$xml->startTag([ $XMLDOOM_NS, 'database' ], %$args);
	}

	foreach my $table ( $schema->get_tables )
	{
		$args = {
			name => $table->name
		};

		if ( $table->extra( 'description' ) )
		{
			$args->{description} = $table->extra( 'description' );
		}
		$xml->startTag('table', %$args);

		# do the columns
		foreach my $field ( $table->get_fields )
		{
			my @args = (
				'name', $field->name,
				'type', uc($field->data_type)
			);
			
			if ( $field->size )
			{
				my $size = $field->size;
				if ( ref($size) eq 'ARRAY' )
				{
					$size = join ',', @$size;
				}
				@args = ( @args, 'size', $size );
			}
			if ( $field->is_primary_key )
			{
				@args = ( @args, 'primaryKey', 'true' );
			}
			if ( !$field->is_nullable )
			{
				@args = ( @args, 'required', 'true' );
			}
			if ( $field->is_auto_increment )
			{
				# TODO: called 'autoIncrement' on the torque DTD.
				@args = ( @args, 'auto_increment', 'true' );
			}
			if ( $field->extra( 'description' ) )
			{
				@args = ( @args, 'description', $field->extra('description') );
			}
			if ( defined $field->default_value )
			{
				@args = ( @args, 'default', $field->default_value );
			}
			if ( $field->extra( 'timestamp' ) )
			{
				@args = ( @args, 'timestamp', $field->extra('timestamp') );
			}
			if ( $field->extra( 'idGenerator' ) and not $compat )
			{
				@args = ( @args, [$XMLDOOM_PERL_NS,'idGenerator'], $field->extra( 'idGenerator' ) );
			}
			
			if ( defined $field->extra( 'list' ) and not $compat )
			{
				$xml->startTag('column', @args);
				$xml->startTag('options');
				foreach my $opt ( @{$field->extra('list')} )
				{
					$xml->dataElement('option', $opt);	
				}
				$xml->endTag('options');
				$xml->endTag('column');
			}
			else
			{
				$xml->emptyTag('column', @args);
			}
		}

		# do the foreign keys
		foreach my $cons ( $table->fkey_constraints )
		{
			my @local_fields = $cons->fields;
			my @foreign_fields = $cons->reference_fields;

			$xml->startTag('foreign-key', foreignTable => $cons->reference_table);
			for( my $i = 0; $i < scalar @local_fields; $i++ )
			{
				$xml->emptyTag('reference',
					local   => $local_fields[$i],
					foreign => $foreign_fields[$i]
				);
			}
			$xml->endTag('foreign-key');
		}

		$xml->endTag('table');
	}

	$xml->endTag('database');
	$xml->end();

	return $str->value();
}

1;

__END__

=pod

=head1 NAME

SQL::Translator::Producer::XML::Xmldoom - Generates XML documents for use with Xmldoom, Apache Torque or Propel

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Producer::XML::Xmldoom;

  my $translator = SQL::Translator->new;
  $translator->producer('SQL::Translator::Producer::XML::Xmldoom');

  # force Torque compatibility
  $translator->producer_args( torque_compatible => 1 );

  # force Propel compatibility
  $translator->producer_args( propel_compatible => 1 );

=head1 DESCRIPTION

This module can generate XML database definitions readable by Xmldoom, Apache Torque
and Propel for PHP5.

=head1 SEE ALSO

SQL::Translator, SQL::Translator::Parser::XML::Xmldoom, Xmldoom

=head1 AUTHORS

David R Snopek E<lt>dsnopek@gmail.comE<gt>

=cut

