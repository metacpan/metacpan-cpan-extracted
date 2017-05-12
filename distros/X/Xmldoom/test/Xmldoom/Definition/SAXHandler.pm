#!/usr/bin/perl -w

package Local::Xmldoom::Definition::SAXHandler;
use base qw(Test::Class);

use Xmldoom::Definition::Database;
use Xmldoom::Schema::Parser;
use Test::More;
use strict;

use Data::Dumper;

sub startup : Test(startup)
{
	my $self = shift;

	my $database_xml = << "EOF";
<?xml version="1.0" standalone="no"?>
<database>
	<table name="book" description="Book Table">
		<column
			name="book_id"
			type="INTEGER"
			required="true"
			primaryKey="true"
		/>
		<column
			name="title"
			type="VARCHAR"
			required="true"
			size="255"
		/>
		<column
			name="isbn"
			type="VARCHAR"
			required="true"
			size="24"
		/>
		<column
			name="publisher_id"
			type="INTEGER"
			required="true"
		/>
		<column
			name="author_id"
			type="INTEGER"
			required="true"
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

	<table name="publisher">
		<column
			name="publisher_id"
			type="INTEGER"
			primaryKey="true"
			auto_increment="true"
		/>
		<column
			name="name"
			required="true"
			type="VARCHAR"
			size="128"
		/>
	</table>

	<table name="author">
		<column
			name="author_id"
			type="INTEGER"
			primaryKey="true"
			auto_increment="true"
		/>
		<column
			name="first_name"
			type="VARCHAR"
			size="128"
			required="true"
		/>
		<column
			name="last_name"
			type="VARCHAR"
			size="128"
			required="true"
		/>
	</table>

	<table name="orders">
		<column
			name="order_id"
			type="INTEGER"
			required="true"
			primaryKey="true"
		/>
		<column
			name="date_opened"
			type="DATETIME"
			timestamp="created"
			required="true"
		/>
		<column
			name="date_shipped"
			type="DATETIME"
			required="false"
		/>

		<foreign-key foreignTable="books_ordered">
			<reference
				local="order_id"
				foreign="order_id"
			/>
		</foreign-key>
	</table>

	<table name="books_ordered">
		<column
			name="order_id"
			type="INTEGER"
			primaryKey="true"
		/>
		<column
			name="book_id"
			type="INTEGER"
			primaryKey="true"
		/>
		<column
			name="quantity"
			type="INTEGER"
			required="true"
			default="1"
		/>

		<foreign-key foreignTable="book">
			<reference
				local="book_id"
				foreign="book_id"
			/>
		</foreign-key>
	</table>
</database>
EOF

	# load the schema
	$self->{schema} = Xmldoom::Schema::Parser::parse({ data => $database_xml });
}

sub setup : Test(setup)
{
	my $self = shift;

	# create a new database object
	$self->{database} = Xmldoom::Definition::Database->new( $self->{schema} );
}

sub testCreateObject : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<objects>
	<object name="Book" table="book"/>
</objects>
EOF

	$self->{database}->parse_object_string( $xml );

	my $object = $self->{database}->get_object('Book');

	ok( defined $object );
}

sub testSimpleProp1 : Test(3)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<objects>
	<object name="Book" table="book">
		<property name="book_id">
			<simple/>
		</property>
		<property
			name="title"
			description="Title">
				<simple/>
		</property>
	</object>
</objects>
EOF

	$self->{database}->parse_object_string( $xml );

	my $object = $self->{database}->get_object('Book');
	my $props  = $object->get_properties();

	is( scalar @$props, 2 );

	my $book_id_prop = $object->get_property('book_id');
	my $title_prop = $object->get_property('title');

	ok( defined $book_id_prop );
	ok( defined $title_prop );
}

1;

