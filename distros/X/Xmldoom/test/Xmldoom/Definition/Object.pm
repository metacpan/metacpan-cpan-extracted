#!/usr/bin/perl -w

package Local::Xmldoom::Definition::Object;
use base qw(Test::Class);

use Xmldoom::Definition::Database;
use Xmldoom::Definition;
use DBIx::Romani::Query::SQL::Generate;
use DBIx::Romani::Query::SQL::Literal;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub startup : Test(startup)
{
	my $self = shift;

	# copied from the Propel book example
	
	my $database_xml = << "EOF";
<?xml version="1.0" standalone="no"?>
<database name="bookstore" defaultIdMethod="native">
	<table name="book" description="Book Table">
		<column
			name="book_id"
			required="true"
			primaryKey="true"
			type="INTEGER"
			description="Book Id"
		/>
		<column
			name="title"
			required="true"
			type="VARCHAR"
			size="255"
			description="Book Title"
		/>
		<column
			name="isbn"
			required="true"
			type="VARCHAR"
			size="24"
			phpName="ISBN"
			description="ISBN Number"
		/>
		<column
			name="publisher_id"
			required="true"
			type="INTEGER"
			description="Foreign Key Publisher"
		/>
		<column
			name="author_id"
			required="true"
			type="INTEGER"
			description="Foreign Key Author"
		/>

		<foreign-key foreignTable="publisher">
			<reference
				local="publisher_id"
				foreign="publisher_id"
			/>
		</foreign-key>

		<foreign-key foreignTable="author">
			<reference
				local="author_id"
				foreign="author_id"
			/>
		</foreign-key>
	</table>

	<!-- to stop explosions -->
	<table name="publisher"/>
	<table name="author"/>

	<table name="test">
		<column
			name="test_id"
			type="INTEGER"
			primaryKey="true"
			auto_increment="true"
		/>
		<column
			name="active"
			type="ENUM"
			required="true"
			default="Y">
			<options>
				<option>Y</option>
				<option>N</option>
			</options>
		</column>
	</table>
</database>
EOF

	my $object_xml = << "EOF";
<?xml version="1.0"?>
<objects>
	<object name="Fake.Book" table="book">
		<property
			name="book_id"
			searchable="false"
			reportable="false">
				<simple/>
		</property>
		<property
			name="title"
			description="Title">
				<simple/>
		</property>
		<property
			name="isbn"
			description="ISBN">
				<simple/>
		</property>
	</object>

	<object name="Fake.Test" table="test">
		<property
			name="active"
			description="Active">
				<simple>
					<trans from="Y" to="1" dir="both"/>
					<trans from="N" to="0" dir="both"/>
					<options inclusive="true">
						<option value="1" description="Active"/>
						<option value="0" description="Inactive"/>
					</options>
					<hints>
						<hint name="short_desc" value="Act"/>
						<hint name="display_crazy"/>
					</hints>
				</simple>
		</property>
	</object>
</objects>
EOF

	my $database;
	
	$database = Xmldoom::Definition::parse_database_string( $database_xml );
	$database->parse_object_string( $object_xml );

	my $book_object = $database->get_object( 'Fake.Book' );
	my $test_object = $database->get_object( 'Fake.Test' );

	#my $book_object = $database->create_object( 'Fake.Book', 'book' );
	# TODO: here we would add some properties.

	# stash for test-tacular use!
	$self->{database}    = $database;
	$self->{book_object} = $book_object;
	$self->{test_object} = $test_object;
}

sub objectSelectQuery : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $query = $self->{book_object}->get_select_query();
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.publisher_id, book.author_id FROM book" );
}

sub objectSelectByKeyQuery : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $query = $self->{book_object}->get_select_by_key_query();
	my $sql = generate_sql( $query, { 'book.book_id' => DBIx::Romani::Query::SQL::Literal->new('TEST') } );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.publisher_id, book.author_id FROM book WHERE book.book_id = 'TEST'" );
}

sub objectInsertQuery : Test(1)
{
	my $self = shift;

	my $query = $self->{book_object}->get_insert_query();
	my $info = {
		book_id      => DBIx::Romani::Query::SQL::Literal->new( 123 ),
		title        => DBIx::Romani::Query::SQL::Literal->new( 'Hitchhikers Guide to the Galaxy' ),
		isbn         => DBIx::Romani::Query::SQL::Literal->new( '0345391802' ),
		publisher_id => DBIx::Romani::Query::SQL::Literal->new( 66 ),
		author_id    => DBIx::Romani::Query::SQL::Literal->new( 666 )
	};
	my $sql = generate_sql( $query, $info );

	is( $sql, "INSERT INTO book (book_id, title, isbn, publisher_id, author_id) VALUES ('123', 'Hitchhikers Guide to the Galaxy', '0345391802', '66', '666')" );
}

sub objectUpdateQuery : Test(1)
{
	my $self = shift;

	my $query = $self->{book_object}->get_update_query();
	my $info = {
		'key.book_id' => DBIx::Romani::Query::SQL::Literal->new( 12 ),
		book_id       => DBIx::Romani::Query::SQL::Literal->new( 123 ),
		title         => DBIx::Romani::Query::SQL::Literal->new( 'Hitchhikers Guide to the Galaxy' ),
		isbn          => DBIx::Romani::Query::SQL::Literal->new( '0345391802' ),
		publisher_id  => DBIx::Romani::Query::SQL::Literal->new( 66 ),
		author_id     => DBIx::Romani::Query::SQL::Literal->new( 666 )
	};
	my $sql = generate_sql( $query, $info );

	is( $sql, "UPDATE book SET book_id = '123', title = 'Hitchhikers Guide to the Galaxy', isbn = '0345391802', publisher_id = '66', author_id = '666' WHERE book_id = '12'" );
}

sub objectDeleteQuery : Test(1)
{
	my $self = shift;

	my $query = $self->{book_object}->get_delete_query();
	my $sql = generate_sql( $query, { book_id => DBIx::Romani::Query::SQL::Literal->new(123) } );

	is( $sql, "DELETE FROM book WHERE book_id = '123'" );
}

#
# TODO: The following two tests don't necessarily belong here!
#

sub objectPropertiesExtra : Test(6)
{
	my $self = shift;

	my @expected   = ( 'Title', 'ISBN' );
	my @searchable = $self->{book_object}->get_searchable_properties();
	my @reportable = $self->{book_object}->get_reportable_properties();

	is( scalar @searchable, scalar @expected );
	is( scalar @reportable, scalar @expected );

	for( my $i = 0; $i < scalar @expected; $i++ )
	{
		is( $searchable[$i]->get_description(), $expected[$i] );
		is( $reportable[$i]->get_description(), $expected[$i] );
	}
}

sub objectPropertyType : Test(7)
{
	my $self = shift;

	my $prop = $self->{test_object}->get_property( 'active' );
	my $data = $prop->get_data_type({ include_options => 1 });

	is( $data->{type}, 'string' );
	is( $data->{options}->[0]->{value}, 1 );
	is( $data->{options}->[0]->{description}, 'Active' );
	is( $data->{options}->[1]->{value}, 0 );
	is( $data->{options}->[1]->{description}, 'Inactive' );
	is( $data->{hints}->{display_crazy}, 1 );
	is( $data->{hints}->{short_desc}, 'Act' );
}

1;

