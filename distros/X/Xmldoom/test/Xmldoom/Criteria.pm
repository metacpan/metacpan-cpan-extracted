#!/usr/bin/perl -w

package Local::Xmldoom::Criteria;
use base qw(Test::Class);

use DBIx::Romani::Query::SQL::Generate;
use DBIx::Romani::Driver::sqlite;
use Xmldoom::Definition;
use Xmldoom::Criteria;
use Xmldoom::Criteria::Search;
use Xmldoom::Criteria::Attribute;
use Xmldoom::Criteria::Literal;
use Xmldoom::Criteria::Property;
use Xmldoom::Criteria::XML;
use XML::GDOME;
use Test::More;
use Test::Exception;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub parse
{
	my $xml = shift;
	
	my $doc   = XML::GDOME->createDocFromString( $xml );
	my $query = Xmldoom::Criteria::XML::create_criteria_from_node( $doc->getDocumentElement() );

	return $query;
}

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
			name="price"
			type="FLOAT"
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
	<table name="author"/>

	<table name="publisher" description="Publisher Table">
		<column
			name="publisher_id"
			required="true"
			primaryKey="true"
			type="INTEGER"
			description="Publisher Id"
		/>
		<column
			name="name"
			required="true"
			type="VARCHAR"
			size="128"
			description="Publisher Name"
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

	<table name="test1">
		<column
			name="id"
			type="INTEGER"
			primary_key="true"
		/>
		<column
			name="other_id1"
			type="INTEGER"
			required="true"
		/>
		<column
			name="other_id2"
			type="INTEGER"
			required="true"
		/>

		<foreign-key foreignTable="test2">
			<reference
				local="other_id1"
				foreign="id"
			/>
		</foreign-key>
		<foreign-key foreignTable="test2">
			<reference
				local="other_id2"
				foreign="id"
			/>
		</foreign-key>
	</table>

	<table name="test2">
		<column
			name="id"
			type="INTEGER"
			primary_key="true"
		/>
		<column
			name="data"
			type="VARCHAR"
			size="50"
			required="true"
		/>
	</table>
</database>
EOF

	my $object_xml = << "EOF";
<?xml version="1.0"?>

<objects>
	<object name="Fake.Book" table="book">
		<property name="book_id">
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
		<property
			name="price"
			description="Price">
				<simple/>
		</property>
	</object>

	<object name="Fake.Publisher" table="publisher">
		<property
			name="name"
			description="Name">
				<simple/>
		</property>
	</object>

	<object name="Fake.Order" table="orders">
		<property name="order_id">
			<simple/>
		</property>
	</object>

	<object name="Fake.BookOrdered" table="books_ordered">
		<property name="book_id">
			<simple/>
		</property>
		<property name="order_id">
			<simple/>
		</property>
	</object>
</objects>
EOF

	my $definition = Xmldoom::Definition::parse_database_string( $database_xml );
	Xmldoom::Definition::parse_object_string( $definition, $object_xml );

	# stash for test-tacular use!
	$self->{database}  = $definition;
	$self->{book}      = $definition->get_object( 'Fake.Book' );
	$self->{publisher} = $definition->get_object( 'Fake.Publisher' );
}

sub criteriaSimple1 : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", "Breakfast of Champions" );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title = 'Breakfast of Champions'" );
}

sub criteriaSimpleClone1 : Test(1)
{
	my $self = shift;

	# create the criteria
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", "Breakfast of Champions" );

	# clone it and then generate the SQL
	my $clone = $criteria->clone();
	my $query = $clone->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title = 'Breakfast of Champions'" );
}

sub criteriaJoin1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "publisher/name", "Prentice Hall" );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND publisher.name = 'Prentice Hall'" );
}

sub criteriaJoin2 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", "Writting Books \"For Dummies\" For Dummies" );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Publisher' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT publisher.publisher_id, publisher.name FROM publisher, book WHERE publisher.publisher_id = book.publisher_id AND book.title = 'Writting Books \"For Dummies\" For Dummies'" );
}

sub criteriaSimpleProp1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Book/isbn', 'XXXXXXXXXX' );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );
	
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.isbn = 'XXXXXXXXXX'" );
}

sub criteriaAttrs1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Publisher/name', 'Prentice Hall' );
	my $query = $criteria->generate_query_for_attrs( $self->{database}, 'book/title' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.title FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND publisher.name = 'Prentice Hall'" );
}

sub criteriaSearchOr : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	my $search = Xmldoom::Criteria::Search->new( 'OR' );
	$search->add( 'Fake.Publisher/name', 'Prentice Hall' );
	$search->add( 'Fake.Publisher/name', 'Lulu Press' );
	$criteria->add( $search );

	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND (publisher.name = 'Prentice Hall' OR publisher.name = 'Lulu Press')" );
}

sub criteriaNotEqual : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Publisher/name', 'Prentice Hall', $Xmldoom::Criteria::NOT_EQUAL );
	my $query = $criteria->generate_query_for_attrs( $self->{database}, 'book/title' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.title FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND publisher.name <> 'Prentice Hall'" );
}

sub criteriaGreaterThan : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Book/price', '19.95', $Xmldoom::Criteria::GREATER_THAN );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );
	
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price > '19.95'" );
}

sub criteriaGreaterEqual : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Book/price', '19.95', $Xmldoom::Criteria::GREATER_EQUAL );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );
	
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price >= '19.95'" );
}

sub criteriaLessThan : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Book/price', '19.95', $Xmldoom::Criteria::LESS_THAN );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );
	
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price < '19.95'" );
}

sub criteriaLessEqual : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Fake.Book/price', '19.95', $Xmldoom::Criteria::LESS_EQUAL );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );
	
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price <= '19.95'" );
}

sub criteriaLike : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", '%breakfast%', $Xmldoom::Criteria::LIKE );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title LIKE \'%breakfast%\'' );
}

sub criteriaNotLike : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", '%breakfast%', $Xmldoom::Criteria::NOT_LIKE );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title NOT LIKE \'%breakfast%\'' );
}

sub criteriaILike : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", '%breakfast%', $Xmldoom::Criteria::ILIKE );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title ILIKE \'%breakfast%\'' );
}

sub criteriaNotILike : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", '%breakfast%', $Xmldoom::Criteria::NOT_ILIKE );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title NOT ILIKE \'%breakfast%\'' );
}

sub criteriaIsNull : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/isbn", undef, $Xmldoom::Criteria::IS_NULL );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.isbn IS NULL' );
}

sub criteriaIsNotNull : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/isbn", undef, $Xmldoom::Criteria::IS_NOT_NULL );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.isbn IS NOT NULL' );
}

sub criteriaBetween : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", [ 'A', 'B' ], $Xmldoom::Criteria::BETWEEN );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title BETWEEN 'A' AND 'B'" );
}

sub criteriaIn : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", [ 'Widgets', 'More Widgets' ], $Xmldoom::Criteria::IN );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title IN ('Widgets','More Widgets')" );
}

sub criteriaNotIn : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/title", [ 'Widgets', 'More Widgets' ], $Xmldoom::Criteria::NOT_IN );
	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title NOT IN ('Widgets','More Widgets')" );
}

sub criteriaSearchOr2 : Test(1)
{
	my $self = shift;

	# create the compiler and see what select SQL it generates
	my $criteria = Xmldoom::Criteria->new();
	my $search   = Xmldoom::Criteria::Search->new( $Xmldoom::Criteria::OR );
	$search->add( 'Fake.Book/title', 'Widgets' );
	$search->add( 'Fake.Book/title', 'More Widgets' );
	$criteria->add( $search );

	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title = 'Widgets' OR book.title = 'More Widgets'" );
	
}

sub criteriaGroupBy : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_group_by_attr( 'book/publisher_id' );

	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql   = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book GROUP BY book.publisher_id" );
}

sub criteriaXmlSimple1 : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<equal>Breakfast of Champions</equal>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title = 'Breakfast of Champions'" );
}

sub criteriaXmlSimple2 : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<attribute name="publisher/name">
			<equal>Prentice Hall</equal>
		</attribute>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND publisher.name = 'Prentice Hall'" );
}

sub criteriaXmlSimple3 : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<attribute name="book/title">
			<equal>Writting Books "For Dummies" For Dummies</equal>
		</attribute>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Publisher' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT publisher.publisher_id, publisher.name FROM publisher, book WHERE publisher.publisher_id = book.publisher_id AND book.title = 'Writting Books \"For Dummies\" For Dummies'" );
}

sub criteriaXmlSearchOr : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<or>
			<property name="Fake.Publisher/name">
				<equal>Prentice Hall</equal>
			</property>
			<property name="Fake.Publisher/name">
				<equal>Lulu Press</equal>
			</property>
		</or>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND (publisher.name = 'Prentice Hall' OR publisher.name = 'Lulu Press')" );
}

sub criteriaXmlNotEqual : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Publisher/name">
			<not-equal>Prentice Hall</not-equal>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_attrs( $self->{database}, 'book/title' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.title FROM book, publisher WHERE book.publisher_id = publisher.publisher_id AND publisher.name <> 'Prentice Hall'" );
}

sub criteriaXmlGreaterThan : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/price">
			<greater-than>19.95</greater-than>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price > '19.95'" );
}

sub criteriaXmlGreaterEqual : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/price">
			<greater-equal>19.95</greater-equal>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price >= '19.95'" );
}

sub criteriaXmlLessThan : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/price">
			<less-than>19.95</less-than>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price < '19.95'" );
}

sub criteriaXmlLessEqual : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/price">
			<less-equal>19.95</less-equal>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.price <= '19.95'" );
}

sub criteriaXmlLike : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<like>\%breakfast%</like>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title LIKE \'%breakfast%\'' );
}

sub criteriaXmlNotLike : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<not-like>\%breakfast%</not-like>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title NOT LIKE \'%breakfast%\'' );
}

sub criteriaXmlIsNull : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/isbn">
			<is-null/>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.isbn IS NULL' );
}

sub criteriaXmlIsNotNull : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/isbn">
			<is-not-null/>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, 'SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.isbn IS NOT NULL' );
}

sub criteriaXmlBetween : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<between min="A" max="B"/>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title BETWEEN 'A' AND 'B'" );
}

sub criteriaXmlIn : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<in>
				<value>Widgets</value>
				<value>More Widgets</value>
			</in>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title IN ('Widgets','More Widgets')" );
}

sub criteriaXmlNotIn : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<not-in>
				<value>Widgets</value>
				<value>More Widgets</value>
			</not-in>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book WHERE book.title NOT IN ('Widgets','More Widgets')" );
}

sub criteriaXmlOrderBy : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<order-by>
		<property name="Fake.Book/title" dir="DESC"/>
		<property name="Fake.Book/isbn"/>
	</order-by>
</criteria>
EOF

	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book ORDER BY book.title DESC, book.isbn ASC" );
}

sub criteriaXmlGroupBy : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<group-by>
		<attribute name="book/publisher_id"/>
	</group-by>
</criteria>
EOF

	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book GROUP BY book.publisher_id" );
}

sub criteriaJoinAttr : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<attribute name="orders/order_id">
			<equal>27</equal>
		</attribute>
		<join-attributes
			name1="orders/order_id"
			name2="books_ordered/order_id"
		/>
		<join-attributes
			name1="books_ordered/book_id"
			name2="book/book_id"
		/>
	</constraints>
</criteria>
EOF

	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	#is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, books_ordered, orders WHERE book.book_id = books_ordered.book_id AND books_ordered.order_id = orders.order_id AND book.book_id = books_ordered.book_id AND (orders.order_id = '27' AND orders.order_id = books_ordered.order_id AND books_ordered.book_id = book.book_id)" ); 
	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, books_ordered, orders WHERE orders.order_id = '27' AND orders.order_id = books_ordered.order_id AND books_ordered.book_id = book.book_id" ); 
}

sub criteriaJoinProp : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<attribute name="orders/order_id">
			<equal>27</equal>
		</attribute>
		<join-properties
			name1="Fake.Order/order_id"
			name2="Fake.BookOrdered/order_id"
		/>
		<join-properties
			name1="Fake.BookOrdered/book_id"
			name2="Fake.Book/book_id"
		/>
	</constraints>
</criteria>
EOF

	my $criteria = parse($xml);
	my $query    = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql      = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, books_ordered, orders WHERE orders.order_id = '27' AND orders.order_id = books_ordered.order_id AND books_ordered.book_id = book.book_id" ); 
}

sub criteriaGenDescription1 : Test(1)
{
	my $self = shift;

	my $xml = << "EOF";
<?xml version="1.0"?>

<criteria>
	<constraints>
		<property name="Fake.Book/title">
			<equal>Dune</equal>
		</property>
		<property name="Fake.Book/isbn">
			<like>123%</like>
		</property>
		<property name="Fake.Book/isbn">
			<not-like>\%ABC</not-like>
		</property>
		<property name="Fake.Book/title">
			<not-equal>Chapterhouse</not-equal>
		</property>
	</constraints>
</criteria>
EOF
	
	my $criteria    = parse($xml);
	my $description = $criteria->generate_description( $self->{database}, 'Fake.Book' );

	is( $description, "ISBN begins with 123 but doesn't end with ABC, and Title is Dune but isn't Chapterhouse");
}

sub criteriaDualLink1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( 'test2/value', 'blah' );

	dies_ok
	{
		# should throw an exception because it is ambiguous how to connect test1 and test2
		# with two seperate foreign-keys connecting them.
		$criteria->generate_query_for_attrs( $self->{database}, 'test1/id' );
	};
}

sub criteriaDualLink2 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->join_attr( 'test1/other_id1', 'test2/id' );
	$criteria->add_attr( 'test2/value', 'blah' );

	my $query = $criteria->generate_query_for_attrs( $self->{database}, 'test1/id' );
	my $sql   = generate_sql( $query );

	is( $sql, "SELECT test1.id FROM test1, test2 WHERE test1.other_id1 = test2.id AND test2.value = 'blah'" );
}

sub criteriaManyToMany1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( 'orders/order_id', '27' );

	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql   = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, orders, books_ordered WHERE books_ordered.order_id = orders.order_id AND book.book_id = books_ordered.book_id AND orders.order_id = '27'" ); 
}

sub criteriaManyToMany2 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( 'orders/order_id', '27' );
	$criteria->add_order_by_attr( 'books_ordered/quantity' );

	my $query = $criteria->generate_query_for_object( $self->{database}, 'Fake.Book' );
	my $sql   = generate_sql( $query );

	is( $sql, "SELECT book.book_id, book.title, book.isbn, book.price, book.publisher_id, book.author_id FROM book, orders, books_ordered WHERE book.book_id = books_ordered.book_id AND books_ordered.order_id = orders.order_id AND orders.order_id = '27' ORDER BY books_ordered.quantity ASC" ); 
}

1;

