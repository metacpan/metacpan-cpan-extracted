
package SQL::Translator::Parser::XML::Xmldoom;
use base qw(SQL::Translator::Parser);

use Xmldoom::Schema::SAXHandler;
use SQL::Translator;
use SQL::Translator::Schema::Constants;
use XML::SAX;
use strict;

sub parse
{
	my ($translator, $data) = @_;

	my $sqlfairy_parser = SQL::Translator::Parser::XML::Xmldoom->new( $translator->schema );
	my $handler = Xmldoom::Schema::SAXHandler->new({ parser => $sqlfairy_parser });
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);

	$parser->parse_string($data);

	return 1;
}

sub new
{
	my $class = shift;
	my $args  = shift;

	my $schema;

	if ( ref($args) eq 'HASH' )
	{
		$schema = $args->{schema};
	}
	else
	{
		$schema = $args;
	}

	my $self = {
		schema => $schema
	};

	bless  $self, $class;
	return $self;
}

sub setup_database
{
	my ($self, $args) = @_;

	if ( defined $args->{name} )
	{
		$self->{schema}->name( $args->{name} );
	}
	if ( defined $args->{defaultIdMethod} )
	{
		$self->{schema}->extra( defaultIdMethod => $args->{defaultIdMethod} );
	}
}

sub add_table
{
	my ($self, $args) = @_;

	my $table = $self->{schema}->add_table(name => $args->{name});

	if ( defined $args->{description} )
	{
		$table->extra( description => $args->{description} );
	}

	return $table;
}

sub finish_table
{
	my ($self, $table) = @_;

	my @primary_key;
	
	foreach my $field ( $table->get_fields() )
	{
		if ( $field->is_primary_key )
		{
			push @primary_key, $field->name;
		}
	}

	# setup the primary key constraint
	$table->add_constraint(
		type   => PRIMARY_KEY,
		fields => \@primary_key
	);
}

sub add_column
{
	my ($self, $table, $args) = @_;

	my $sqlfairy = {
		name        => $args->{name},
		data_type   => $args->{type},
	};

	if ( defined $args->{required} )
	{
		$sqlfairy->{is_nullable} = not $args->{required};
	}
	if ( defined $args->{primary_key} )
	{
		$sqlfairy->{is_primary_key} = $args->{primary_key};
	}
	if ( defined $args->{size} )
	{
		$sqlfairy->{size} = $args->{size};
	}
	if ( defined $args->{auto_increment} )
	{
		$sqlfairy->{is_auto_increment} = $args->{auto_increment};
	}
	if ( defined $args->{default} )
	{
		$sqlfairy->{default_value} = $args->{default}
	}

	my $field = $table->add_field( %$sqlfairy );

	if ( defined $args->{description} )
	{
		$field->extra( description => $args->{description} );
	}
	if ( defined $args->{id_generator} )
	{
		$field->extra( idGenerator => $args->{id_generator} );
	}
	if ( defined $args->{timestamp} )
	{
		$field->extra( timestamp => $args->{timestamp} );
	}
	if ( defined $args->{options} )
	{
		$field->extra( list => $args->{options} );
	}
}

sub add_foreign_key
{
	my ($self, $table, $args) = @_;

	$table->add_constraint(
		type             => FOREIGN_KEY,
		fields           => $args->{local_columns},
		reference_fields => $args->{foreign_columns},
		reference_table  => $args->{foreign_table}
	);
}

1;

__END__

=pod

=head1 NAME

SQL::Translator::Parser::XML::Xmldoom - parser for Xmldoom and compitable Propel and Torque documents

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Parser::XML::Xmldoom;
  
  my $translator = SQL::Translator->new;
  $translator->parser('SQL::Translator::Parser::XML::Xmldoom');

=head1 DESCRIPTION

This can read anything from the Xmldoom format and enough of Propel and Torque to generate
good SQL CREATE script using any of the standard Producers.

=head1 AUTHOR

David R Snopek E<lt>dsnopek@gmail.comE<gt>

=head1 SEE ALSO

SQL::Translator, Xmldoom

=cut

