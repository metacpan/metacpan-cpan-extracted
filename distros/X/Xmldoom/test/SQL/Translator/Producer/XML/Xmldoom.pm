#!/usr/bin/perl -w

package Local::SQL::Translator::Producer::XML::Xmldoom;
use base qw(Test::Class);

use SQL::Translator;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Parser::XML::Xmldoom;
use SQL::Translator::Producer::XML::Xmldoom;
use Test::More;
use strict;

use Data::Dumper;

sub round_trip
{
	my $translator = SQL::Translator->new(@_);

	$translator->parser('SQL::Translator::Parser::XML::Xmldoom');
	$translator->producer('SQL::Translator::Producer::XML::Xmldoom');

	my $output = $translator->translate
		or die $translator->error;
	
	return $output;
}

sub testDatabaseTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0" encoding="utf-8"?>

<database name="bookstore" defaultIdMethod="native" xmlns="http://gna.org/projects/xmldoom/database"></database>
EOF

	is( round_trip(data => $xml), $xml );
}

sub testTableTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0" encoding="utf-8"?>

<database xmlns="http://gna.org/projects/xmldoom/database">
<table name="book" description="Book Table"></table>
</database>
EOF

	is( round_trip(data => $xml), $xml );
}

sub testColumnTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0" encoding="utf-8"?>

<database xmlns="http://gna.org/projects/xmldoom/database">
<table name="book">
<column name="book_id" type="INTEGER" primaryKey="true" auto_increment="true" description="Book Id" perl:idGenerator="Some::Perl::Class" xmlns:perl="http://gna.org/projects/xmldoom/database-perl" />
<column name="title" type="VARCHAR" size="255" required="true" description="Book Title" default="Unknown" />
<column name="active" type="ENUM">
<options>
<option>Y</option>
<option>N</option>
</options>
</column>
<column name="last_changed" type="DATETIME" timestamp="current" />
</table>
</database>
EOF

	is( round_trip(data => $xml), $xml );
}

sub testForeignKeyTag : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0" encoding="utf-8"?>

<database xmlns="http://gna.org/projects/xmldoom/database">
<table name="book">
<column name="book_id" type="INTEGER" primaryKey="true" auto_increment="true" />
<column name="author_id" type="INTEGER" required="true" />
<column name="title" type="VARCHAR" size="255" required="true" default="Unknown" />
<foreign-key foreignTable="author">
<reference local="author_id" foreign="author_id" />
</foreign-key>
</table>
<table name="author">
<column name="author_id" type="INTEGER" primaryKey="true" auto_increment="true" />
</table>
</database>
EOF

	is( round_trip(data => $xml), $xml );
}

1;

