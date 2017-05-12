#!/usr/bin/perl -w

package Local::Xmldoom::Definition::Database;
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

	<table name="publisher_extra">
		<column
			name="publisher_id"
			type="INTEGER"
			primaryKey="true"
		/>
		<column
			name="extra"
			type="VARCHAR"
			size="200"
		/>

		<foreign-key foreignTable="publisher">
			<reference
				local="publisher_id"
				foreign="publisher_id"
			/>
		</foreign-key>
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

sub testLinks1 : Test(8)
{
	my $self = shift;

	my $database = $self->{database};

	# TODO: probably belongs in a test/Xmldoom/Definition/Database.pm.

	my $links = $database->find_links('book', 'author');

	is( scalar @$links, 1 );

	my $link = $links->[0];
	is( scalar @{$link->get_foreign_keys()}, 1 );
	is( $link->get_relationship(), 'many-to-one' );

	my $fn = $link->get_foreign_keys()->[0]->get_column_names();
	is( scalar @$fn, 1 );
	is( $fn->[0]->{local_table},    'book' );
	is( $fn->[0]->{local_column},   'author_id' );
	is( $fn->[0]->{foreign_table},  'author' );
	is( $fn->[0]->{foreign_column}, 'author_id' );
}

sub testLinks2 : Test(1)
{
	my $self = shift;

	my $database = $self->{database};

	my $links = $database->find_links('author', 'book');
	my $link  = $links->[0];

	is( $link->get_relationship(), 'one-to-many' );
}

sub testLinks3 : Test(1)
{
	my $self = shift;

	my $database = $self->{database};

	my $links = $database->find_links('publisher_extra', 'publisher');
	my $link  = $links->[0];

	is ( $link->get_relationship(), 'one-to-one' );
}

sub testLinks4 : Test(6)
{
	my $self = shift;

	my $database = $self->{database};

	my $links = $database->find_links('publisher_extra', 'book');
	my $link  = $links->[0];

	is ( $link->get_relationship(), 'one-to-many' );

	my $fn = $link->get_foreign_keys()->[0]->get_column_names();
	is( scalar @$fn, 1 );
	is( $fn->[0]->{local_table},    'publisher_extra' );
	is( $fn->[0]->{local_column},   'publisher_id' );
	is( $fn->[0]->{foreign_table},  'book' );
	is( $fn->[0]->{foreign_column}, 'publisher_id' );
}

sub testLinks5 : Test(11)
{
	my $self = shift;

	my $database = $self->{database};

	my $links = $database->find_links('orders', 'book');
	my $link  = $links->[0];

	is ( $link->get_relationship(), 'many-to-many' );

	my $fn1 = $link->get_foreign_keys()->[0]->get_column_names();
	is( scalar @$fn1, 1 );
	is( $fn1->[0]->{local_table},    'orders' );
	is( $fn1->[0]->{local_column},   'order_id' );
	is( $fn1->[0]->{foreign_table},  'books_ordered' );
	is( $fn1->[0]->{foreign_column}, 'order_id' );

	my $fn2 = $link->get_foreign_keys()->[1]->get_column_names();
	is( scalar @$fn2, 1 );
	is( $fn2->[0]->{local_table},    'books_ordered' );
	is( $fn2->[0]->{local_column},   'book_id' );
	is( $fn2->[0]->{foreign_table},  'book' );
	is( $fn2->[0]->{foreign_column}, 'book_id' );
}

1;

