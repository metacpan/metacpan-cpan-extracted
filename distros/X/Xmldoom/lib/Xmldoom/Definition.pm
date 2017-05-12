
package Xmldoom::Definition;

use Xmldoom::Definition::Database;
use Xmldoom::Schema::Parser;
use strict;

use Data::Dumper;

sub parse_database_string
{
	my $args = shift;

	my $input;
	my $shared;

	if ( ref($args) eq 'HASH' )
	{
		$input  = $args->{string};
		$shared = $args->{shared};
	}
	else
	{
		$input = $args;
	}

	my $schema   = Xmldoom::Schema::Parser::parse({ data => $input });
	my $database = Xmldoom::Definition::Database->new( $schema );

	return $database;
}

sub parse_database_uri
{
	my $args = shift;

	my $uri;
	my $shared;

	if ( ref($args) eq 'HASH' )
	{
		$uri    = $args->{uri};
		$shared = $args->{shared};
	}
	else
	{
		$uri = $args;
	}

	my $schema   = Xmldoom::Schema::Parser::parse({ uri => $uri });
	my $database = Xmldoom::Definition::Database->new( $schema );

	return $database;
}

#
# DRS: These are only retained for compatibility!  The will disappear soon.
#

sub parse_object_string
{
	my ($database, $data) = @_;
	return $database->parse_object_string($data);
}

sub parse_object_uri
{
	my ($database, $uri) = @_;
	return $database->parse_object_uri($uri);
}

1;

