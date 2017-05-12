#!/usr/bin/perl -w

package Local::example::BookStore;
use base qw(Test::Class);

use Xmldoom::Definition;
use Xmldoom::Object;
use Xmldoom::Object::XMLGenerator;
use Xmldoom::Criteria;
use DBIx::Romani::Connection::Factory;
use DBIx::Romani::Driver::sqlite;
use Exception::Class::TryCatch;
use Test::More;
use Date::Calc qw( Today Add_Delta_Days );
use DBI;
use strict;

use example::BookStore::Object;
use example::BookStore::Book;
use example::BookStore::Author;
use example::BookStore::Publisher;
use example::BookStore::Order;
use example::BookStore::BooksOrdered;

use Data::Dumper;

sub create_column
{
	my $column = shift;

	my $s = sprintf "%s %s", $column->{name}, $column->{type};
	
#	if ( $column->{primary_key} )
#	{
#		$s .= " PRIMARY KEY";
#	}

	return $s;
}

sub create_primary_key
{
	my $table = shift;

	my @keys;

	foreach my $column ( @{$table->get_columns()} )
	{
		if ( $column->{primary_key} )
		{
			push @keys, $column->{name};
		}
	}

	return "PRIMARY KEY (" . join(', ', @keys) . ")";
}

sub startup : Test(startup)
{
	my $self = shift;

	# convenience
	$self->{database} = $example::BookStore::Object::DATABASE;
}

sub setup : Test(setup)
{
	my $self = shift;

	my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","");

	# TODO: we should really have built in support for this somewhere!
	while ( my ($name, $table) = each %{$self->{database}->get_tables()} )
	{
		my @cols = map { create_column($_) } @{$table->get_columns()};
		push @cols, create_primary_key($table);

		my $SQL = "CREATE TABLE '$name' ( " . join(', ', @cols) . " )";

		#print "$SQL\n";
		$dbh->do( $SQL );
	}

	$self->{dbh} = $dbh;

	$self->{dbh}->func( 'NOW', 0, sub {
		my @t = gmtime time();
		return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
	}, 'create_function' );

	# add some test data
	$self->insert( "author", 
		[ 1, 'Russell A', 'Snopek' ], 
		[ 2, 'Douglas N', 'Adams' ],

		# Next two I made up to have the same first name
		[ 3, 'John A',    'Jenkins' ],
		[ 4, 'John A',    'Oppenheimer' ],

		[ 5, 'Kurt',      'Vonnegut' ]
	);
	$self->insert( "publisher",
		[ 1, 'Lulu Press' ],
		[ 2, 'Wings' ],
		[ 3, 'Del Rey' ],
		[ 4, 'Pocket' ],
	);
	$self->insert( "orders",
		[ 1, '2006-03-10 05:37:31', '' ],
	);
	$self->insert( "books_ordered",
		[ 1, 1, 2 ],
		[ 1, 2, 1 ],
	);

	# calculate a date eleven days ago.
	my ($year,$month,$day);
	($year,$month,$day) = Today();
	($year,$month,$day) = Add_Delta_Days($year,$month,$day,-11);
	my $t_date = sprintf "%04d-%02d-%02d 13:27:44", $year, $month, $day;

	$self->insert( "book",
		[ 1, "My Science Fiction Autobiography",          "141162730X", 1, 1, $t_date, $t_date ],
		[ 2, "The Hitchhikers Guide to the Galaxy",       "0517149257", 2, 2, $t_date, $t_date ],
		[ 3, "The Restaurant at the End of the Universe", "0345391810", 3, 2, $t_date, $t_date ],
		[ 4, "Life, the Universe and Everything",         "0345391829", 3, 2, $t_date, $t_date ],
		[ 5, "So Long and Thanks for All the Fish",       "0345391837", 3, 2, $t_date, $t_date ],
		[ 6, "Mostly Harmless",                           "0345418778", 3, 2, $t_date, $t_date ],
	);

	# connect the database to this SQLite connection
	my $driver  = DBIx::Romani::Driver::sqlite->new();
	my $factory = DBIx::Romani::Connection::Factory->new({ dbh => $dbh, driver => $driver });

	$self->{database}->set_connection_factory( $factory );
}

sub insert
{
	my $self       = shift;
	my $table_name = shift;

	while ( my $values = shift )
	{
		my $SQL = "INSERT INTO '$table_name' VALUES ( " . join( ", ", map { "'$_'" } @$values ) . " )";
		#print "$SQL\n";
		$self->{dbh}->do( $SQL );
	}

}

sub exampleCriteria1 : Test(2)
{
	my $self = shift;

	my $author = example::BookStore::Author->load({ author_id => 1 });
	my $criteria = Xmldoom::Criteria->new({ parent => $author });
	my @books = example::BookStore::Book->Search( $criteria );

	is( scalar @books, 1 );
	is( $books[0]->_get_attr( 'title' ), "My Science Fiction Autobiography" );
}

sub exampleCriteria2 : Test(1)
{
	my $self = shift;

	my $author = example::BookStore::Author->load({ author_id => 2 });
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( 'Book/author', $author );
	my @books = example::BookStore::Book->Search( $criteria );

	is ( scalar @books, 5 );
}

sub exampleCriteriaAttrs1 : Test(1)
{
	my $self = shift;

	my $author   = example::BookStore::Author->load({ author_id => 1 });
	my $criteria = Xmldoom::Criteria->new();
	$criteria->add( "Book/author", $author );

	my @list = example::BookStore::Book->SearchAttrs( $criteria, "title" );

	is( $list[0]->{title}, "My Science Fiction Autobiography" );
}

sub exampleCriteriaDistinctAttrs1 : Test(4)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();

	my @list = example::BookStore::Author->SearchDistinctAttrs( $criteria, "first_name" );

	is( $list[0]->{first_name}, "Russell A" );
	is( $list[1]->{first_name}, "Douglas N" );
	is( $list[2]->{first_name}, "John A" );
	is( $list[3]->{first_name}, "Kurt" );
}

sub databaseCriteria1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_attr( "book/author_id", 1 );

	my @list = $example::BookStore::Object::DATABASE->Search( $criteria, "book/title" );

	is ( $list[0]->{title}, "My Science Fiction Autobiography" );
}

sub examplePropsSimple1 : Test(2)
{
	my $self = shift;

	my $author = example::BookStore::Author->load({ author_id => 1 });

	is( $author->get_first_name(), 'Russell A' );
	is( $author->get_last_name(),  'Snopek' );
}

sub examplePropsObjectGet1 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher = $book->get_publisher();

	is( $publisher->get_name(), "Lulu Press" );
}

sub examplePropsObjectGet2 : Test(4)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 3 });
	my $books = $publisher->get_books();

	is( $books->[0]->get_title(), "The Restaurant at the End of the Universe" );
	is( $books->[1]->get_title(), "Life, the Universe and Everything" );
	is( $books->[2]->get_title(), "So Long and Thanks for All the Fish" );
	is( $books->[3]->get_title(), "Mostly Harmless" );
}

sub examplePropsObjectGet3 : Test(2)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 3 });
	my $books = $publisher->get_books({ title => 'Mostly Harmless' });

	is ( scalar @$books, 1 );
	is ( $books->[0]->get_title(), 'Mostly Harmless' );
}

sub examplePropsObjectSet1 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 2 });
	my $publisher = example::BookStore::Publisher->load({ publisher_id => 3 });

	$book->set_publisher( $publisher );

	is ( $book->_get_attr('publisher_id'), 3 );
}

sub examplePropsObjectCreate1 : Test(5)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 4 });
	my $author = example::BookStore::Author->load({ author_id => 2 });
	my $book = example::BookStore::Book->new();

	$book->set_title     ( 'Long Dark Tea Time of the Soul' );
	$book->set_isbn      ( '0671742515' );
	$book->set_author    ( $author );
	$book->set_publisher ( $publisher );

	$book->save();

	is( $book->_get_attr( 'book_id' ), 7 );

	# re-load book
	$book = example::BookStore::Book->load({ book_id => 7 });
	is( $book->get_title(), 'Long Dark Tea Time of the Soul' );
	is( $book->get_isbn(),  '0671742515' );
	is( $book->get_author()->get_last_name(), 'Adams' );
	is( $book->get_publisher()->get_name(),   'Pocket' );
}

sub examplePropsObjectCreate2 : Test(5)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 4 });
	my $author = example::BookStore::Author->load({ author_id => 2 });
	my $book = example::BookStore::Book->new({
		title     => 'Long Dark Tea Time of the Soul',
		isbn      => '0671742515',
		author    => $author,
		publisher => $publisher,
	});

	$book->save();

	is( $book->_get_attr( 'book_id' ), 7 ) || return;

	# re-load book
	$book = example::BookStore::Book->load({ book_id => 7 });
	is( $book->get_title(), 'Long Dark Tea Time of the Soul' );
	is( $book->get_isbn(),  '0671742515' );
	is( $book->get_author()->get_last_name(), 'Adams' );
	is( $book->get_publisher()->get_name(),   'Pocket' );
}

sub examplePropsObjectAdd1 : Test(5)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 4 });
	my $author = example::BookStore::Author->load({ author_id => 2 });

	my $book = $author->add_book({
		title     => 'Long Dark Tea Time of the Soul',
		isbn      => '0671742515',
		publisher => $publisher,
	});
	$book->save();

	is( $book->_get_attr( 'book_id' ), 7 ) || return;

	# re-load book
	$book = example::BookStore::Book->load({ book_id => 7 });
	is( $book->get_title(), 'Long Dark Tea Time of the Soul' );
	is( $book->get_isbn(),  '0671742515' );
	is( $book->get_author()->get_last_name(), 'Adams' );
	is( $book->get_publisher()->get_name(),   'Pocket' );

	#$self->dump_table('book');
}

sub exampleDelete1 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	$book->delete();

	try eval
	{
		# attempt to reload
		example::BookStore::Book->load({ book_id => 1 });
	};

	my $error = catch;
	ok ( defined $error );
	#$error->rethrow() if $error;
}

sub exampleChildParent1 : Test(2)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher = $book->get_publisher();

	is( $publisher->{parent}, $book );

	$publisher->set_name( 'Test' );
	$book->save();

	$publisher = $book->get_publisher();
	is( $publisher->get_name(), 'Test' );
}

sub exampleChildParent2 : Test(2)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->load({ publisher_id => 3 });
	my $criteria  = Xmldoom::Criteria->new( $publisher );
	my @books     = example::BookStore::Book->Search( $criteria );

	is( $books[0]->{parent}, $publisher );

	$books[0]->set_title( 'Blah' );
	$publisher->save();

	# reload
	@books = example::BookStore::Book->Search( $criteria );
	is( $books[0]->get_title(), 'Blah' );
}

sub exampleChildParent3 : Test(1)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->new({ name => "My Publisher" });
	my $author    = example::BookStore::Author->load({ author_id => 3 });
	my $book      = $publisher->add_book({ author => $author, title => "My Book", isbn => "XYZ" });

	$publisher->save();

	# make sure that the automatically generated id is passed into the child
	is ( $book->_get_attr('publisher_id'), 5 );
}

sub exampleChildParent4 : Test(2)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->new({ name => "My Publisher", publisher_id => 27 });
	my $author    = example::BookStore::Author->load({ author_id => 3 });
	my $book      = $publisher->add_book({ author => $author, title => "My Book", isbn => "XYZ" });

	# make sure that the parent property is being pulled directly from the parent object.
	is( $publisher->get_publisher_id(),   27 );
	is( $book->_get_attr('publisher_id'), $publisher->get_publisher_id() );

	$publisher->save();
}

sub exampleChildParent5 : Test(7)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->new({ name => "My Publisher", publisher_id => 27 });
	my $author    = example::BookStore::Author->load({ author_id => 3 });
	my $book      = $publisher->add_book({ author => $author, title => "My Book", isbn => "XYZ" });

	my @books;

	# pull the list of the unsaved objects
	@books = $publisher->get_books();
	is( scalar @books,          1 );
	is( $books[0]->get_title(), "My Book" );
	is( $books[0]->{new},       1 );

	# now save ...
	$publisher->save();

	# and pull the now saved objects
	@books = $publisher->get_books();
	is( scalar @books,          1 );
	is( $books[0]->get_title(), "My Book" );
	is( $books[0]->{new},       0 );
	is( $books[1],              undef );
}

sub exampleChildParent6 : Test(7)
{
	my $self = shift;

	my $author = example::BookStore::Author->new({
		first_name => 'John B',
		last_name  => 'Smith'
	});

	my $book = example::BookStore::Book->new({
		author    => $author,
		publisher => example::BookStore::Publisher->load({ publisher_id => 1 }),
		title     => 'My Book',
		isbn      => 'XYZ'
	});

	# load the unsaved object
	is( $book->get_author(),           $author );
	is( $book->_get_attr('author_id'), undef );

	$book->save();

	# confirm that we have a id now for author_id
	is( $book->_get_attr('author_id'), 6 );

	my $author2 = $book->get_author();

	# now that the object is saved, we should get a new instance when we
	# query for it.
	isnt( $author2, $author );

	# but it should still be the same data in the database
	is( $author2->get_author_id(),  $author->get_author_id() );
	is( $author2->get_first_name(), $author->get_first_name() );
	is( $author2->get_last_name(),  $author->get_last_name() );
}

sub exampleOrderBy1 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_order_by_prop( 'Book/title' );
	my @books = example::BookStore::Book->Search( $criteria );

	is ( $books[0]->get_title(), 'Life, the Universe and Everything' );
}

sub exampleOrderBy2 : Test(1)
{
	my $self = shift;

	my $criteria = Xmldoom::Criteria->new();
	$criteria->add_order_by_attr( 'book/title' );
	my @books = example::BookStore::Book->Search( $criteria );

	is ( $books[0]->get_title(), 'Life, the Universe and Everything' );
}

sub exampleXml1 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });

	my $generator;
	$generator = Xmldoom::Object::XMLGenerator->new({ expand_objects => 0 });
	$generator->startTag('books');
	$generator->generate($book, 'book');
	$generator->endTag('books');
	$generator->close();

	my $exp = << "EOF";
<books>
<book book_id="1">
<book_id>1</book_id>
<title>My Science Fiction Autobiography</title>
<isbn>141162730X</isbn>
<publisher publisher_id="1" />
<author author_id="1" />
<age>11</age>
<publisher_id>1</publisher_id>
</book>
</books>
EOF

	is ( $generator->get_string(), $exp );
}

sub exampleXml2 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });

	my $generator;
	$generator = Xmldoom::Object::XMLGenerator->new({ expand_objects => 1 });
	$generator->startTag('books');
	$generator->generate($book, 'book');
	$generator->endTag('books');
	$generator->close();

	my $exp = << "EOF";
<books>
<book book_id="1">
<book_id>1</book_id>
<title>My Science Fiction Autobiography</title>
<isbn>141162730X</isbn>
<publisher publisher_id="1">
<publisher_id>1</publisher_id>
<name>Lulu Press</name>
</publisher>
<author author_id="1">
<author_id>1</author_id>
<first_name>Russell A</first_name>
<last_name>Snopek</last_name>
</author>
<age>11</age>
<publisher_id>1</publisher_id>
</book>
</books>
EOF

	is ( $generator->get_string(), $exp );
}

sub exampleCustomProperty : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });

	is( $book->get_age(), 11 );
}

sub exampleComplexPropOptions1 : Test(1)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher_id = $book->_get_property("publisher_id");

	is( $publisher_id->get_pretty(), "Lulu Press" );
}

sub exampleComplexPropOptions2 : Test(8)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher_id = $book->_get_property("publisher_id");
	my $data_type = $publisher_id->get_data_type({ include_options => 1 });
	my $options = $data_type->{options};

	is ( $options->[0]->{value}, 3 );
	is ( $options->[0]->{description}, "Del Rey" );
	is ( $options->[1]->{value}, 1 );
	is ( $options->[1]->{description}, "Lulu Press" );
	is ( $options->[2]->{value}, 4 );
	is ( $options->[2]->{description}, "Pocket" );
	is ( $options->[3]->{value}, 2 );
	is ( $options->[3]->{description}, "Wings" );
}

sub exampleComplexPropOptions3 : Test(1)
{
	my $self = shift;

	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher = $book->_get_property("publisher");

	is( $publisher->get_pretty(), "Lulu Press" );
}

sub exampleComplexPropOptions4 : Test(8)
{
	my $self = shift;

	my $book = example::BookStore::Book->load({ book_id => 1 });
	my $publisher = $book->_get_property("publisher");
	my $data_type = $publisher->get_data_type({ include_options => 1 });
	my $options = $data_type->{options};

	is ( $options->[0]->{value}->{publisher_id}, 1 );
	is ( $options->[0]->{description}, "Lulu Press" );
	is ( $options->[1]->{value}->{publisher_id}, 2 );
	is ( $options->[1]->{description}, "Wings" );
	is ( $options->[2]->{value}->{publisher_id}, 3 );
	is ( $options->[2]->{description}, "Del Rey" );
	is ( $options->[3]->{value}->{publisher_id}, 4 );
	is ( $options->[3]->{description}, "Pocket" );
}

sub exampleManyToManySimple1 : Test(4)
{
	my $self = shift;

	my $order = example::BookStore::Order->load({ order_id => 1 });
	my @books_ordered = $order->get_books_ordered();

	is( $books_ordered[0]->get_book()->get_title(), "My Science Fiction Autobiography" );
	is( $books_ordered[0]->get_quantity(), 2 );
	is( $books_ordered[1]->get_book()->get_title(), "The Hitchhikers Guide to the Galaxy" );
	is( $books_ordered[1]->get_quantity(), 1 );
}

sub exampleManyToManyComplex1 : Test(2)
{
	my $self = shift;

	my $order = example::BookStore::Order->load({ order_id => 1 });
	my @books = $order->get_books();

	is( $books[0]->get_title(), "My Science Fiction Autobiography" );
	is( $books[1]->get_title(), "The Hitchhikers Guide to the Galaxy" );
}

sub exampleCustomIdGenerator : Test(1)
{
	my $self = shift;

	my $publisher = example::BookStore::Publisher->new({
		name => "Mine Publisher"
	});

	$publisher->save();

	ok(1);
}

sub exampleGetAllProps : Test(5)
{
	my $self = shift;

	my $book  = example::BookStore::Book->load({ book_id => 1 });
	my $props = $book->get();

	is( $props->{title},                     "My Science Fiction Autobiography" );
	is( $props->{isbn},                      "141162730X" );
	is( $props->{author}->get_first_name(),  "Russell A" );
	is( $props->{author}->get_last_name(),   "Snopek" );
	is( $props->{publisher}->get_name(),     "Lulu Press" );
}

1;

