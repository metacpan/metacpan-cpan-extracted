#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;

BEGIN {
  # Because use YATT::Lite::WebMVC0::DBSchema::DBIC loads DBIx::Class::Schema.
  foreach my $req (qw(DBD::SQLite DBIx::Class::Schema SQL::Abstract)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

my $DBNAME = shift || ':memory:';

{
  # DBIC direct access.

  my $CLASS = 'MyDB1';
  package MyDB1;
  use YATT::Lite::WebMVC0::DBSchema::DBIC
    (__PACKAGE__, verbose => $ENV{DEBUG_DBSCHEMA}
     , [Author => undef
	, author_id => [int => -primary_key, -autoincrement
			, ['has_many:books'
			   => [Book => undef
			       , book_id => [int => -primary_key
					     , -autoincrement]
			       , author_id => [int => -indexed
					       , [belongs_to => 'Author']]
			       , name => 'text']]]
	, name => [text => -indexed]]);

# -- MyDB1::Result::Author->has_many(books, MyDB1::Result::Book, author_id)
# -- MyDB1::Result::Book->belongs_to(Author, MyDB1::Result::Author, author_id)

  package main;
  my $schema = $CLASS->connect("dbi:SQLite:dbname=$DBNAME");

  isa_ok($schema, "DBIx::Class::Schema");
  isa_ok($schema->YATT_DBSchema, "YATT::Lite::WebMVC0::DBSchema::DBIC");

  $schema->YATT_DBSchema->deploy;

  ok my $author = $schema->resultset('Author'), "resultset Author";
  is $author, $schema->YATT_DBSchema->resultset('Author')
    , "DBSchema->resultset() is delegated to DBIC";
  is $author, $schema->YATT_DBSchema->model('Author')
    , "model() is alias of resultset()";

  ok my $book = $schema->resultset('Book'), "resultset Book";

  is((my $foo = $author->create({name => 'Foo'}))->id
     , 1, "Author create name=Foo");

  is $foo->in_storage, 1, "created author is in_storage";
  isnt $author->find({name => 'Foo'}), $foo
    , "author->find returns different instance";

  {
    is $schema->to_find(Author => 'name')->('Foo')
      , $foo->id, "to_find returns same id";
  }

  is $book->create({name => "Foo's 1st book", author_id => $foo->id})->id
    , 1, "Book create Foo's 1st";

  is $foo->create_related(books => {name => "Foo's 2nd book"})->id
    , 2, "Book create Foo's 2nd";

  is((my $bar = $author->create({name => 'Bar'}))->id
     , 2, "Author create name=Bar");

  is $book->create({name => "Bar's 1st book", author_id => $bar->id})->id
    , 3, "Book create Bar 1st";

  is $author->count, 2, "Total number of authors";

  is $book->count, 3, "Total number of books";

  is_deeply [sort map {$_->name} $foo->search_related('books')->all]
    , ["Foo's 1st book", "Foo's 2nd book"]
      , "Foo's books: foo->search_rel";
  # print $_->name(), "\n" for $foo->search_related('books');
  #is $author->search_related(books => {name => 'Foo'})->count
  #  , 2, "Foo's books: author->search_rel";
  is $author->search_related(books => {'me.name' => 'Foo'})->count
    , 2, "Foo's books: author->search_rel";

  #----------------------------------------
  {
    my $aid = 3; # next (expected) author id
    my $bid = 4; # next (expected) book id

    my $ins_auth = $schema->to_insert(Author => 'name');
    my $ins_book = $schema->to_insert(Book => qw(author_id name));
    my $sel_auth = $schema->to_find(Author => 'name');

    is $ins_auth->('Qux'), $aid, 'Qux is inserted';
    is $ins_book->($aid, "Qux's 1st book"), $bid
      , "Qux's 1st book is inserted";
    is $ins_book->($aid, "Qux's 2nd book"), $bid+1
      , "Qux's 2nd book is inserted";
    is $sel_auth->('Qux'), $aid, 'Qux is found in Authors';

    # to_fetch returns sub which returns sth.
    is_deeply $schema->to_fetch(Book => author_id => 'name')
      ->($aid)->fetchall_arrayref
	, [["Qux's 1st book"], ["Qux's 2nd book"]], "fetchall arrayref";
    is_deeply $schema->to_fetch(Book => author_id => [book_id => 'name']
				, order_by => 'book_id')
      ->($aid)->fetchall_arrayref
	, [[$bid, "Qux's 1st book"]
	   , [$bid+1, "Qux's 2nd book"]], "fetchall arrayref, many cols";

    my $enc_auth = $schema->to_encode(Author => 'name');

    is $enc_auth->('Quxx'), $aid+1, "enc_auth(new Quxx) == $aid+1";
    is $enc_auth->('Qux'), $aid, "enc_auth(known Qux) == $aid";
  }
}

{
  # Wrapper API.

  my $CLASS = 'MyDB1'; # Same class

  my $deleted = 0;
  {
    ok(my $schema = $CLASS->YATT_DBSchema
       ->clone(connection_spec => [sqlite => $DBNAME]
	       , on_destroy => sub { $deleted = 1; })
       , "DBIC->YATT_DBSchema");

    is ref($schema), 'YATT::Lite::WebMVC0::DBSchema::DBIC'
    , "ref YATT_DBSchema";

    is ref($schema->dbic), $CLASS, "ref dbic";

    $schema->resultset('Author')
      ->create({name => 'Foo author'
		, books => [{name => 'Bar'}, {name => 'Baz'}]});

    is_deeply [sort map {$_->name}
	       $schema->resultset('Author')->find({Name => 'Foo author'})
	       ->search_related('books')]
      , [qw/Bar Baz/], "DBIC wrapper works";
    }

  ok $deleted, "DBSchema is deleted";
}

{
  my $CLASS = 'MyDB2';
  package MyDB2;
  use YATT::Lite::WebMVC0::DBSchema::DBIC
    (__PACKAGE__, verbose => $ENV{DEBUG_DBSCHEMA}
     , [User => undef
	, uid => [integer => -primary_key]
	, fname => 'text'
	, lname => 'text'
	, email => 'text'
	, encpass => 'text'
	, tmppass => 'text'
	, [-has_many
	   , [Address => undef
	    , addrid => [integer => -primary_key]
	    , owner =>  [int => [belongs_to => 'User']]
	    , country => 'text'
	    , zip => 'text'
	    , prefecture => 'text'
	    , city => 'text'
	    , address => 'text']]
	, [-has_many
	   , [Entry => undef
	      , eid => [integer => -primary_key]
	      , owner => [int => [belongs_to => 'User']]
	      , title => 'text'
	      , text  => 'text']]
       ]);

  package main;
  my $schema = $CLASS->connect("dbi:SQLite:dbname=$DBNAME");
  $schema->YATT_DBSchema->deploy;

  ok my $user = $schema->resultset('User'), "resultset User";
  ok my $entries = $schema->resultset('Entry'), "resultset Entry";

  is((my $foo = $user->create({fname => 'Foo', lname => 'Bar'}))->id
     , 1, "User.create.id");

  is($entries->create({title => 'First entry', text => "Hello world!"
		       , owner => $foo->id})->id
     , 1, "Entry.create.id");
}

{
  my $CLASS = 'MyDB3';
  package MyDB3;
  use YATT::Lite::WebMVC0::DBSchema::DBIC
    (__PACKAGE__, verbose => $ENV{DEBUG_DBSCHEMA}
     , [user => undef
	, id => [integer => -primary_key, -autoincrement]
	, name => 'text'
	, ['has_many:user_address'
	   => [user_address => undef
	       , user => [int => [belongs_to => 'user']]
	       , address => [int => [belongs_to =>
				     [address => undef
				      , id => [int => -primary_key]
				      , street => 'text'
				      , town => 'text'
				      , area_code => 'text'
				      , country => 'text'
				      , ['has_many:user_address' => 'user_address', 'address']
				      , ['many_to_many:users'
					 => 'user_address', 'user']
				     ]]]
	       , [primary_key => qw(user address)]]]
	, ['many_to_many:addresses'
	   => 'user_address', 'address']
       ]);

  package main;
  my $schema = $CLASS->connect("dbi:SQLite:dbname=$DBNAME");
  $schema->YATT_DBSchema->deploy;

  is((my $user = $schema->resultset('user')->create({name => 'Foo'}))->id
     , 1, "[$CLASS] user.create");
  is((my $address = $user->add_to_addresses
      ({country => 'United Kingdom'
	, area_code => 'XYZ'
	, town => 'London'
	, street => 'Sesame'
       }))->id
    , 1, "[$CLASS] user.add_to_address");
}

{
  my $CLASS = 'MyDB4';
  package MyDB4;
  use YATT::Lite::WebMVC0::DBSchema::DBIC
    (__PACKAGE__, verbose => $ENV{DEBUG_DBSCHEMA}
     , [ticket => undef
	, tn => [int => -primary_key, -autoincrement]
	, at => 'datetime'
	, title => 'text'
	, description => 'text'
	, [values => [qw(at title)]
	   , ['2010-01-01T09:00', '1st ticket']
	   , ['2010-01-02T15:00', '2nd ticket']
	  ]
       ]

     , [chng => undef
	, cn => [int => -primary_key, -autoincrement]
	, at => 'datetime'
	, comment => 'text'
	, [values => [qw(at comment)]
	   , ['2010-01-01T12:00', '1st chng']
	   , ['2010-01-02T18:00', '2nd chng']
	  ]
       ]

     , [timeline => {view => <<SQL }
select tn as num, 'ticket' as type, at, title from ticket
union all
select cn as num, 'chng' as type, at, comment as title from chng
SQL
	, num => 'int'
	, type => 'text'
	, at => 'datetime'
	, title => 'text'
       ]
    );

  package main;
  my $schema = $CLASS->connect("dbi:SQLite:dbname=$DBNAME");
  $schema->YATT_DBSchema->deploy;

  is_deeply [map {[$_->num, $_->type, $_->at, $_->title]}
	     $schema->resultset('timeline')
	     ->search(undef, {order_by => 'at'})->all]
    , [[1, ticket => '2010-01-01T09:00', '1st ticket']
       , [1, chng => '2010-01-01T12:00', '1st chng']
       , [2, ticket => '2010-01-02T15:00', '2nd ticket']
       , [2, chng => '2010-01-02T18:00', '2nd chng']
      ], "$CLASS timeline";
}

done_testing();
