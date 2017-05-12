#!/usr/bin/perl -w

package Local::Xmldoom::Schema::Parser;
use base qw(Test::Class);

use Xmldoom::Schema::Parser;
use Test::More;
use strict;

use Data::Dumper;

sub parse
{
	return Xmldoom::Schema::Parser::parse(@_);
}

sub testDatabaseTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database name="bookstore" defaultIdMethod="native">
</database>
EOF

	my $schema = parse({ data => $xml });

	ok( 1 );

	#is( $schema->name, 'bookstore' );
	#is( $schema->extra('defaultIdMethod'), 'native');
}

sub testTableTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database>
	<table name="book" description="Book Table">
	</table>
</database>
EOF

	my $schema = parse({ data => $xml });
	my $table  = $schema->get_table('book');

	ok( defined $table );

	#is( $table->name, 'book' );
	#is( $table->extra('description'), 'Book Table');
}

sub testColumnTag : Test(18)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database
xmlns="http://gna.org/projects/xmldoom/database"
xmlns:perl="http://gna.org/projects/xmldoom/database-perl">
	<table name="book">
		<column
			name="book_id"
			primaryKey="true"
			type="INTEGER"
			description="Book Id"
			auto_increment="true"
			perl:idGenerator="Some::Perl::Class"
		/>
		<column
			name="title"
			required="true"
			type="VARCHAR"
			size="255"
			default="Unknown"
			description="Book Title"
		/>
		<column
			name="active"
			type="ENUM">
				<options>
					<option>Y</option>
					<option>N</option>
				</options>
		</column>
		<column
			name="last_changed"
			type="DATETIME"
			timestamp="current"
		/>
	</table>
</database>
EOF

	my $schema = parse({ data => $xml });
	my $table  = $schema->get_table('book');
	my $field1 = $table->get_column('book_id');
	my $field2 = $table->get_column('title');
	my $field3 = $table->get_column('active');
	my $field4 = $table->get_column('last_changed');

	# check first field
	is( $field1->{name},               'book_id' );
	is( $field1->{type},               'INTEGER' );
	is( $field1->{primary_key},        1 );
	is( $field1->{required},           0 );
	is( $field1->{auto_increment},     1 );
	#is( $field1->extra('description'), 'Book Id' );
	is( $field1->{id_generator}, 'Some::Perl::Class' );

	# check second field
	is( $field2->{name},               'title' );
	is( $field2->{type},               'VARCHAR' );
	is( $field2->{primary_key},        0 );
	is( $field2->{required},           1 );
	is( $field2->{auto_increment},     0 );
	#is( $field2->extra('description'), 'Book Title' );
	is( $field2->{default},            'Unknown' );

	# check enum field
	my $options = $field3->{options};
	is( scalar @$options, 2 );
	is( $options->[0], 'Y' );
	is( $options->[1], 'N' );

	# check the timestamp attribute
	is( $field4->{timestamp}, 'current' );

	my $primary_key = $table->get_primary_key;
	ok( scalar @$primary_key == 1 );
	is( $primary_key->[0]->{name}, 'book_id' );
}

sub testForeignKeyTag : Test(6)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database>
	<table name="book">
		<column
			name="book_id"
			type="INTEGER"
			primaryKey="true"
			auto_increment="true"
		/>
		<column
			name="author_id"
			type="INTEGER"
			required="true"
		/>
		<column
			name="title"
			required="true"
			type="VARCHAR"
			size="255"
			default="Unknown"
		/>

		<foreign-key foreignTable="author">
			<reference
				local="author_id"
				foreign="author_id"
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
	</table>
</database>
EOF

	my $schema = parse({ data => $xml });
	my $table  = $schema->get_table('book');

	my $foreign_keys = $table->get_foreign_keys;
	ok( scalar @$foreign_keys == 1 );

	my $ref_table    = $foreign_keys->[0]->get_reference_table_name();
	my $local_cols   = $foreign_keys->[0]->get_local_column_names();
	my $foreign_cols = $foreign_keys->[0]->get_foreign_column_names();

	is( $ref_table,            'author' );
	is( scalar @$local_cols,   1 );
	is( $local_cols->[0],      'author_id' );
	is( scalar @$foreign_cols, 1 );
	is( $foreign_cols->[0],    'author_id' );
}

1;

