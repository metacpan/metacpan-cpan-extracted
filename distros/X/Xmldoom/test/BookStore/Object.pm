
package test::BookStore::Object;
use base qw(Xmldoom::Object);

use Xmldoom::Definition;
use strict;

our $DATABASE;

# nifty little shortcut
sub BindToObjectName
{
	my ($class, $object_name) = @_;

	my $object = $DATABASE->get_object ( $object_name );

	$class->BindToObject( $object );

	return $object;
}

BEGIN
{
	my $database_xml = << "EOF";
<?xml version="1.0" standalone="no"?>
<database
xmlns="http://gna.org/projects/xmldoom/database"
xmlns:perl="http://gna.org/projects/xmldoom/database-perl"
name="bookstore" defaultIdMethod="native">
	<table name="book" description="Book Table">
		<column
			name="book_id"
			required="true"
			primaryKey="true"
			type="INTEGER"
			description="Book Id"
			auto_increment="true"
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
		<column
			name="created"
			type="DATETIME"
			timestamp="create"
		/>
		<column
			name="last_changed"
			type="TIMESTAMP"
			timestamp="current"
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

	<table name="publisher" description="Publisher Table">
		<column
			name="publisher_id"
			required="true"
			primaryKey="true"
			type="INTEGER"
			description="Publisher Id"
			perl:idGenerator="test::BookStore::PublisherIdGenerator"
		/>
		<column
			name="name"
			required="true"
			type="VARCHAR"
			size="128"
			description="Publisher Name"
		/>
	</table>

	<table name="author" description="Author Table">
		<column
			name="author_id"
			required="true"
			primaryKey="true"
			type="INTEGER"
			auto_increment="true"
			description="Author Id"
		/>
		<column
			name="first_name"
			required="true"
			type="VARCHAR"
			size="128"
			description="First Name"
		/>
		<column
			name="last_name"
			required="true"
			type="VARCHAR"
			size="128"
			description="Last Name"
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

	<!-- Used to test using two connections to the same table.  This
	     type of operation isnt fully supported, so we cant integrate
		 it into any of the normal example objects. -->
	<table name="test_1">
		<column
			name="id"
			type="INTEGER"
			primaryKey="true"
		/>
		<column
			name="book_id_1"
			type="INTEGER"
			required="true"
		/>
		<column
			name="book_id_2"
			type="INTEGER"
			required="true"
		/>

		<foreign-key foreignTable="book">
			<reference
				local="book_id_1"
				foreign="book_id"
			/>
		</foreign-key>

		<foreign-key foreignTable="book">
			<reference
				local="book_id_2"
				foreign="book_id"
			/>
		</foreign-key>
	</table>
</database>
EOF
	
	my $object_xml = << "EOF";
<?xml version="1.0"?>
<objects
xmlns="http://gna.org/projects/xmldoom/object"
xmlns:perl="http://gna.org/projects/xmldoom/object-perl">

<object name="Book" table="book" perl:class="test::BookStore::Book">
	<property name="book_id">
		<simple/>
	</property>
	<property name="title">
		<simple/>
	</property>
	<property name="isbn">
		<simple/>
	</property>
	<property name="publisher">
		<object name="Publisher">
			<options
				inclusive="true"
				property="name"/>
		</object>
	</property>
	<property name="author">
		<object name="Author"/>
	</property>
		
	<!-- a custom property type! -->
	<property name="age">
		<custom perl:class="test::BookStore::BookAgeProperty"/>
	</property>

	<!-- a simple property with slightly complex options -->
	<property name="publisher_id">
		<simple>
			<options
				inclusive="true"
				table="publisher"
				column="name">
					<!-- put them in reverse order, cuz we can! -->
					<criteria>
						<order-by>
							<attribute name="publisher/name"/>
						</order-by>
					</criteria>
			</options>
		</simple>
	</property>
</object>

<object name="Author" table="author" perl:class="test::BookStore::Author">
	<property name="author_id">
		<simple/>
	</property>
	<property name="first_name">
		<simple/>
	</property>
	<property name="last_name">
		<simple/>
	</property>

	<!-- external property -->
	<property name="book">
		<object name="Book"/>
	</property>
</object>

<object name="Publisher" table="publisher" perl:class="test::BookStore::Publisher">
	<property name="publisher_id">
		<simple/>
	</property>
	<property name="name">
		<simple/>
	</property>

	<!-- external property -->
	<property name="book">
		<object name="Book"/>
	</property>
</object>

<object name="Order" table="orders" perl:class="test::BookStore::Order">
	<property name="date_opened">
		<simple/>
	</property>
	<property name="date_shipped">
		<simple/>
	</property>
	<property name="books_ordered"
		get_name="get_books_ordered"
		set_name="add_book_ordered">
			<object name="BooksOrdered"/>
	</property>
	<property name="book">
		<object name="Book" inter_table="books_ordered"/>
	</property>
</object>

<object name="BooksOrdered" table="books_ordered" perl:class="test::BookStore::BooksOrdered">
	<property name="book">
		<object name="Book"/>
	</property>
	<property name="quantity">
		<simple/>
	</property>
</object>

<object name="Test1" table="test_1" perl:class="test::BookStore::Test1">
	<property name="id">
		<simple/>
	</property>
	<property name="book1">
		<object name="Book">
			<key>
				<attribute name="book_id_1"/>
			</key>
		</object>
	</property>
	<property name="book2">
		<object name="Book">
			<key>
				<attribute name="book_id_2"/>
			</key>
		</object>
	</property>
</object>
</objects>
EOF

	# read the database definition
	$DATABASE = Xmldoom::Definition::parse_database_string( $database_xml );

	# read the object description
	Xmldoom::Definition::parse_object_string( $DATABASE, $object_xml );
}

1;

