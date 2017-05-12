
package Xmldoom::Definition::Database;

use Xmldoom::Definition::Object;
use Xmldoom::Definition::SAXHandler;
use Xmldoom::Definition::LinkTree;
use Xmldoom::Definition::Link;
use Xmldoom::Threads;
use Exception::Class::TryCatch;
use XML::SAX::ParserFactory;
use strict;

use Data::Dumper;

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
		schema             => $schema,
		objects            => { },

		real_links         => Xmldoom::Definition::LinkTree->new(),
		inferred_links     => Xmldoom::Definition::LinkTree->new(),
		many_to_many_links => Xmldoom::Definition::LinkTree->new(),
		
		connection_factory => undef,
	};

	# go through and add all of the real links from the schema
	while ( my ($table_name, $table) = each %{$self->{schema}->get_tables()} )
	{
		foreach my $fkey ( @{$table->get_foreign_keys()} )
		{
			$self->{real_links}->add_link( Xmldoom::Definition::Link->new($fkey) );
		}
	}

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $args->{shared});
}

sub get_connection_factory { return shift->{connection_factory}; }
sub get_schema             { return shift->{schema}; }

sub get_tables { return shift->{schema}->get_tables; }
sub get_table
{
	my ($self, $name) = @_;
	return $self->{schema}->get_table($name);
}
sub has_table
{
	my ($self, $name) = @_;
	return $self->{schema}->has_table($name);
}

sub get_objects { return shift->{objects}; }
sub get_object
{
	my ($self, $name) = @_;

	if ( not defined $self->{objects}->{$name} )
	{
		die "Unknown object named '$name'";
	}
	
	return $self->{objects}->{$name};
}
sub has_object
{
	my ($self, $name) = @_;
	return defined $self->{objects}->{$name};
}

sub set_connection_factory
{
	my ($self, $factory) = @_;
	$self->{connection_factory} = $factory;
}

sub create_db_connection
{
	return shift->get_connection_factory()->create();
}

sub create_object
{
	my ($self, $object_name, $table_name) = @_;

	if ( defined $self->{objects}->{$object_name} )
	{
		die "Object definition for \"$object_name\" already added.";
	}

	# add and return the object definition
	my $object = Xmldoom::Definition::Object->new({
		definition  => $self,
		object_name => $object_name,
		table_name  => $table_name,
		shared      => Xmldoom::Threads::is_shared($self)
	});
	$self->{objects}->{$object_name} = $object;
	return $object;
}

sub find_links
{
	my ($self, $table1_name, $table2_name) = @_;

	if ( not $self->has_table($table1_name) or not $self->has_table($table2_name) )
	{
		die "Cannot find connections between one or more non-existant tables";
	}

	my $links;

	# NOTE:  In case anyone is wondering, the links are seperated into three different
	# trees inorder to seperate which pools of links is used for calculating the links
	# in another pool.  Specifically, when we caclulate the inferred links we want to
	# draw *only* on real links, and not other inferred links or many to many links.
	# Similarily, when we calculate many to many links we only want to consider real links
	# and inferred links but not other many to many links.

	# check stored real links
	$links = $self->{real_links}->get_links($table1_name, $table2_name);
	if ( defined $links )
	{
		return $links;
	}

	# check stored inferred links
	$links = $self->_find_inferred_links($table1_name, $table2_name);
	if ( defined $links )
	{
		return $links;
	}

	# check stored many-to-many links
	$links = $self->_find_many_to_many_links($table1_name, $table2_name);
	if ( defined $links )
	{
		return $links;
	}

	# attempt to find new inferred links
	return [];
}

sub _find_inferred_links
{
	my ($self, $table1_name, $table2_name) = @_;

	# first check to see if there is a cached link available
	my $cached_links = $self->{inferred_links}->get_links($table1_name, $table2_name);
	if ( defined $cached_links )
	{
		return $cached_links;
	}

	my @ret;

	# now, attempt to find an inferred link, begginning by grabing a list of all the tables
	# that this table is links to.
	my $link_hash = $self->{real_links}->get_links($table1_name);
	while ( my ($inter_table, $links) = each %$link_hash )
	{
		for my $link ( @$links )
		{
			# here we check to see if there are any links and the linked table, to the desired
			# table by way of the columns specified at the end of the original link.
			my $other_links = $self->{real_links}->get_links($inter_table, $table2_name, $link->get_end_column_names());

			# multiple links are ok --- they just mean that there are multiple inferred links,
			# with the associated problems handled elsewhere, just as they would have to be
			# with the relevent real links.
			foreach my $other_link ( @$other_links )
			{
				if ( defined $other_link )
				{
					my $inferred_link = Xmldoom::Definition::Link->new(
						Xmldoom::Schema::ForeignKey->new({
							parent          => $self->get_schema()->get_table($table1_name),
							reference_table => $table2_name,
							local_columns   => $link->get_start_column_names(),
							foreign_columns => $other_link->get_end_column_names()
						})
					);

					# cache the result for later
					$self->{inferred_links}->add_link( $link );

					push @ret, $inferred_link;
				}
			}
		}
	}

	if ( scalar @ret > 0 )
	{
		return \@ret;
	}

	return undef;
}

sub _find_many_to_many_links
{
	my ($self, $table1_name, $table2_name) = @_;

	# first check to see if there is a cached link available
	my $cached_links = $self->{many_to_many_links}->get_links($table1_name, $table2_name);
	if ( defined $cached_links )
	{
		return $cached_links;
	}

	my @ret;

	# get all the connections to other tables from the real links and the inferred links
	# while purposely not checking the many-to-many links which would just create problems.
	my $link_hash = { };
	my $temp;
	if ( defined ($temp = $self->{real_links}->get_links($table1_name)) )
	{
		$link_hash = { %$link_hash, %$temp };
	}
	if ( defined ($temp = $self->{inferred_links}->get_links($table1_name)) )
	{
		$link_hash = { %$link_hash, %$temp };
	}

	# we loop through simply looking for a table we are linked to which is also linked to
	# the desired table.  We don't have to check to see if this "inferred" or truely "many
	# to many" because we know that the inferred keys will be checked first.  This has the
	# weakness of only working for single table "jumps," but any type of recursition scares
	# me just now.
	while ( my ($inter_table, $links) = each %$link_hash )
	{
		for my $link ( @$links )
		{
			my $other_links = $self->{real_links}->get_links($inter_table, $table2_name);

			# return multiple links as we find them, to be dealt with by the calling code.
			foreach my $other_link ( @$other_links )
			{
				if ( defined $other_link )
				{
					my $many_to_many_link = Xmldoom::Definition::Link->new([
						$link->get_foreign_key(),
						$other_link->get_foreign_key()
					]);

					# cache the result for later
					$self->{many_to_many_links}->add_link( $many_to_many_link );

					push @ret, $many_to_many_link;
				}
			}
		}
	}


	if ( scalar @ret > 0 )
	{
		return \@ret;
	}

	return undef;
}

sub parse_object_string
{
	my ($self, $input) = @_;

	# build the parser
	my $handler = Xmldoom::Definition::SAXHandler->new( $self );
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);

	# phase 1 -- Create the objects and attach to respective tables
	$parser->parse_string($input);

	# phase 2 -- Actually add all the properties to the objects
	$parser->parse_string($input);
}

sub parse_object_uri
{
	my ($self, $uri) = @_;

	# build the parser
	my $handler = Xmldoom::Definition::SAXHandler->new( $self );
	my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);

	# phase 1 -- Create the objects and attach to respective tables
	$parser->parse_uri($uri);

	# phase 2 -- Actually add all the properties to the objects
	$parser->parse_uri($uri);
}

sub SearchRS
{
	my $self     = shift;
	my $criteria = shift;

	my $query = $criteria->generate_query_for_attrs( $self, @_ );

	my $conn;
	my $rs;

	# connect and query
	try eval
	{
		$conn = $self->create_db_connection();
		#printf STDERR "Search(): %s\n", $conn->generate_sql($query);
		$rs = $conn->prepare( $query )->execute();
	};

	catch my $err;
	if ( $err )
	{
		$conn->disconnect() if defined $conn;
		$err->rethrow();
	}

	return $rs;
}

sub Search
{
	my $class = shift;
	my $rs    = $class->SearchRS( @_ );
	
	my @ret;

	# unravel our result set
	while ( $rs->next() )
	{
		push @ret, $rs->get_row();
	}

	return wantarray ? @ret : \@ret;
}

#sub DESTROY
#{
#	my $self = shift;
#
#	if ( $self->get_dbh() )
#	{
#		$self->get_dbh()->disconnect();
#		$self->set_dbh( undef );
#	}
#}

1;

