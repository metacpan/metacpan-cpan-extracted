
package Xmldoom::Schema::Parser;

use Xmldoom::Schema;
use Xmldoom::Schema::SAXHandler;
use XML::SAX;
use strict;

sub parse
{
	my $args = shift;

	my $schema;
	my $uri;
	my $data;
	my $shared;

	if ( ref($args) eq 'HASH' )
	{
		$schema = $args->{schema};
		$uri    = $args->{uri};
		$data   = $args->{data};
	}
	else
	{
		$schema = $args;
		$data   = shift;
	}

	if ( not defined $schema )
	{
		$schema = Xmldoom::Schema->new({ shared => $shared });
	}

	my $xmldoom_parser = Xmldoom::Schema::Parser->new( $schema );
	my $handler = Xmldoom::Schema::SAXHandler->new({ parser => $xmldoom_parser });
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);

	if ( defined $uri )
	{
		$parser->parse_uri($uri);
	}
	elsif ( defined $data )
	{
		$parser->parse_string($data);
	}

	return $schema;
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
		schema => $schema,
	};

	bless  $self, $class;
	return $self;
}

sub setup_database
{
	my ($self, $args) = @_;
}

sub add_table
{
	my ($self, $args) = @_;

	my $table = $self->{schema}->create_table( $args->{name} );

	return $table;
}

sub finish_table
{
	my ($self, $table) = @_;
}

sub add_column
{
	my ($self, $table, $args) = @_;

	$table->add_column( $args );
}

sub add_foreign_key
{
	my ($self, $table, $args) = @_;

	$table->add_foreign_key({
		reference_table => $args->{foreign_table},
		local_columns   => $args->{local_columns},
		foreign_columns => $args->{foreign_columns}
	});
}

1;

