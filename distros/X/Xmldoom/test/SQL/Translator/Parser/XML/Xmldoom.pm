#!/usr/bin/perl -w

package Local::SQL::Translator::Parser::XML::Xmldoom;
use base qw(Test::Class);

use SQL::Translator;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Parser::XML::Xmldoom;
use Test::More;
use strict;

use Data::Dumper;

sub parse
{
	my $translator = SQL::Translator->new(@_);

	SQL::Translator::Parser::XML::Xmldoom::parse($translator, ${$translator->data});

	return $translator->schema;
}

sub testDatabaseTag : Test(2)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database
	name="bookstore"
	defaultIdMethod="native"
	defaultJavaType="primitive"
	package="package"
	baseClass="com.myapp.om.BaseClass"
	basePeer="com.myapp.om.BasePeer"
	defaultJavaNamingMethod="underscore"
	heavyIndexing="false">
</database>
EOF

	my $schema = parse(data => $xml);

	is( $schema->name, 'bookstore' );
	is( $schema->extra('defaultIdMethod'), 'native');
}

sub testTableTag : Test(2)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>
<database>
	<table name="book" description="Book Table">
	</table>
</database>
EOF

	my $schema = parse(data => $xml);
	my $table  = $schema->get_table('book');

	is( $table->name, 'book' );
	is( $table->extra('description'), 'Book Table');
}

sub testColumnTag : Test(20)
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

	my $schema = parse(data => $xml);
	my $table  = $schema->get_table('book');
	my $field1 = $table->get_field('book_id');
	my $field2 = $table->get_field('title');
	my $field3 = $table->get_field('active');
	my $field4 = $table->get_field('last_changed');

	# check first field
	is( $field1->name,                  'book_id' );
	is( $field1->data_type,             'INTEGER' );
	is( $field1->is_primary_key,        1 );
	is( $field1->is_nullable,           1 );
	is( $field1->is_auto_increment,     1 );
	is( $field1->extra('description'), 'Book Id' );
	is( $field1->extra('idGenerator'), 'Some::Perl::Class' );

	# check second field
	is( $field2->name,                  'title' );
	is( $field2->data_type,             'VARCHAR' );
	is( $field2->is_primary_key,        0 );
	is( $field2->is_nullable,           0 );
	is( $field2->is_auto_increment,     0 );
	is( $field2->extra('description'), 'Book Title' );
	is( $field2->default_value,        'Unknown' );

	# check enum field
	my $options = $field3->extra( 'list' );
	is( scalar @$options, 2 );
	is( $options->[0], 'Y' );
	is( $options->[1], 'N' );

	# check the timestamp attribute
	is( $field4->extra('timestamp'), 'current' );

	my @primary_key;
	foreach my $constraint ( $table->get_constraints )
	{
		if ( $constraint->type eq PRIMARY_KEY )
		{
			@primary_key = $constraint->field_names;
			last;
		}
	}

	ok( scalar @primary_key == 1 );
	is( $primary_key[0], 'book_id' );
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

	my $schema = parse(data => $xml);
	my $table  = $schema->get_table('book');
	
	my @foreign_keys;
	foreach my $constraint ( $table->get_constraints )
	{
		if ( $constraint->type eq FOREIGN_KEY )
		{
			push @foreign_keys, $constraint;
		}
	}

	ok( scalar @foreign_keys == 1 );
	is( $foreign_keys[0]->reference_table, 'author' );
	
	my @local_fields   = $foreign_keys[0]->fields;
	my @foreign_fields = $foreign_keys[0]->reference_fields;

	ok( scalar @local_fields == 1 );
	is( $local_fields[0], 'author_id' );
	ok( scalar @foreign_fields == 1 );
	is( $foreign_fields[0], 'author_id' );
}

1;

