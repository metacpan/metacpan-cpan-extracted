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
use YATT::Lite::Util qw(terse_dump);

foreach my $req (qw(DBD::SQLite SQL::Abstract)) {
  unless (eval qq{require $req}) {
    plan skip_all => "$req is not installed."; exit;
  }
}

my $CLASS = 'YATT::Lite::WebMVC0::DBSchema';
use_ok($CLASS);

my $DBNAME = shift || ':memory:';

my @schema1
  = [Author => undef
	, author_id => [int => -primary_key, -autoincrement
			, ['has_many:books:author_id'
			   => [Book => undef
			       , book_id => [int => -primary_key
					     , -autoincrement]
			       , author_id => [int => -indexed
					       , [belongs_to => 'Author']]
			       , name => 'text']]]
	, name => 'text'];

{
  my $THEME = "[schema only]";
  my $schema = $CLASS->new(@schema1);
  is_deeply [$schema->list_tables], [qw(Author Book)]
    , "$THEME list_tables";

  is_deeply [map {ref $_} $schema->list_tables(raw => 1)]
    , [("${CLASS}::Table") x 2]
      , "$THEME list_tables raw=>1";

  is ref $schema->get_table('Author'), "${CLASS}::Table"
    , "$THEME get_table Author";

  is_deeply [map {[$_, $schema->list_table_columns($_)]} $schema->list_tables]
    , [[Author => qw(author_id name)], [Book => qw(book_id author_id name)]]
      , "$THEME list_table_columns";

  $schema->extend_table(Book => undef
			, price => 'int'
			, isbn => [text => -unique]);

  is_deeply [$schema->list_table_columns('Book')]
    , [qw(book_id author_id name price isbn)]
      , "$THEME extend_table";

  is_deeply [$schema->list_relations('Author')]
    , [[has_many => 'books', author_id => 'Book']]
      , "$THEME relations: Author has_many Book";

  is_deeply [$schema->list_relations('Book')]
    , [[belongs_to => 'author', author_id => 'Author']]
      , "$THEME relations: Book belongs_to Author";
}

{
  my $THEME = "[sqlite create]";
  my $dbh = DBI->connect("dbi:SQLite:dbname=$DBNAME", undef, undef
			 , {PrintError => 0, RaiseError => 1, AutoCommit => 0});

  ok(my $schema = $CLASS->new(DBH => $dbh, @schema1)
     , "$THEME Can new without connection spec");

  eq_or_diff join("", map {chomp;"$_;\n"} $schema->sql_create), <<'END'
CREATE TABLE Author
(author_id integer primary key
, name text);
CREATE TABLE Book
(book_id integer primary key
, author_id int
, name text);
CREATE INDEX Book_author_id on Book(author_id);
END
    , "$THEME SQL returned by sql_create";

  $schema->extend_table(Book => undef
			, price => 'int'
			, isbn => [text => -unique]);

  eq_or_diff join("", map {chomp;"$_;\n"} $schema->sql_create), <<'END'
CREATE TABLE Author
(author_id integer primary key
, name text);
CREATE TABLE Book
(book_id integer primary key
, author_id int
, name text
, price int
, isbn text unique);
CREATE INDEX Book_author_id on Book(author_id);
END
    , "$THEME (after extend_table) SQL returned by sql_create";


  is_deeply $dbh->selectall_arrayref
    (q|select name from sqlite_master where type = 'table'|)
      , [], "$THEME no table before create";

  $schema->create(sqlite => $DBNAME);

  is_deeply $schema->dbh->selectall_arrayref
    (q|select name from sqlite_master where type = 'table'|)
      , [['Author'], ['Book']], "$THEME dbschema create worked";

  # to_insert, to_find returns sub which directly returns interest.
  my $ins_auth = $schema->to_insert(Author => 'name');
  my $ins_book = $schema->to_insert(Book => qw(author_id name));
  my $sel_auth = $schema->to_find(Author => 'name');
  is $ins_auth->('Foo'), 1, 'Foo is inserted';
  is $ins_book->(1, "Foo's 1st book"), 1, "Foo's 1st book is inserted";
  is $ins_book->(1, "Foo's 2nd book"), 2, "Foo's 2nd book is inserted";
  is $sel_auth->('Foo'), 1, 'Foo is found in Authors';

  # to_fetch returns sub which returns sth.
  is_deeply $schema->to_fetch(Book => author_id => 'name')
    ->(1)->fetchall_arrayref
      , [["Foo's 1st book"], ["Foo's 2nd book"]], "fetchall arrayref";
  is_deeply $schema->to_fetch(Book => author_id => [book_id => 'name']
			      , order_by => 'book_id')
    ->(1)->fetchall_arrayref
      , [[1, "Foo's 1st book"]
	 , [2, "Foo's 2nd book"]], "fetchall arrayref, many cols";

  my $enc_auth = $schema->to_encode(Author => 'name');

  is $enc_auth->('Bar'), 2, "enc_auth(Foo) == 1";
  is $enc_auth->('Foo'), 1, "enc_auth(Bar) == 2";
}

{
  my $THEME = "[auto connect/create]";
  ok(my $schema = $CLASS->new(connection_spec => [sqlite => $DBNAME], @schema1)
     , "$THEME Can create");

  is_deeply $schema->dbh->selectall_arrayref
    (q|select name from sqlite_master where type = 'table'|)
      , [['Author'], ['Book']]
	, "$THEME dbschema can connect";
}

{
  my $THEME = "[Relation in column_list]";
  my $schema = $CLASS->new
    ([Author => undef
      , author_id => [int => -primary_key, -autoincrement]
      , name => 'text'
      , [has_many => [Book => undef
		      , book_id => [int => -primary_key, -autoincrement]
		      , author_id => [int => -indexed
				     , [belongs_to => 'Author']]
		      , name => 'text']
	, 'author_id', {join_type => 'left'}]
     ]);

  is_deeply [$schema->list_tables], [qw(Author Book)]
    , "$THEME list_tables";

  is_deeply [map {ref $_} $schema->list_tables(raw => 1)]
    , [("${CLASS}::Table") x 2]
      , "$THEME list_tables raw=>1";

  is ref $schema->get_table('Author'), "${CLASS}::Table"
    , "$THEME get_table Author";

  is_deeply [map {[$_, $schema->list_table_columns($_)]} $schema->list_tables]
    , [[Author => qw(author_id name)], [Book => qw(book_id author_id name)]]
      , "$THEME list_table_columns";

  is_deeply [$schema->list_relations('Author')]
    , [[has_many => 'book', author_id => 'Book']]
      , "$THEME relations: Author has_many Book";

  is_deeply [$schema->list_relations('Book')]
    , [[belongs_to => 'author', author_id => 'Author']]
      , "$THEME relations: Book belongs_to Author";
}

{
  my $THEME = "[Encoded relation]";
  my $schema = $CLASS->new
    ([Book => undef
      , book_id => [int => -primary_key, -autoincrement]
      , author_id => [int => -indexed
		      # XXX: [-encoded_by] == [-belongs_to <=> -has_many]
		      , [-belongs_to
			 , [Author => undef
			    , author_id => [int => -primary_key, -autoincrement]
			    , name => 'text'
			    , [-has_many => 'Book', 'author_id']
			   ]]]
      , name => 'text']
     );

  is_deeply [$schema->list_tables], [qw(Book Author)]
    , "$THEME list_tables";

  is_deeply [map {ref $_} $schema->list_tables(raw => 1)]
    , [("${CLASS}::Table") x 2]
      , "$THEME list_tables raw=>1";

  is ref $schema->get_table('Author'), "${CLASS}::Table"
    , "$THEME get_table Author";

  is_deeply [map {[$_, $schema->list_table_columns($_)]} $schema->list_tables]
    , [[Book => qw(book_id author_id name)], [Author => qw(author_id name)]]
      , "$THEME list_table_columns";

  is_deeply [$schema->list_relations('Author')]
    , [[has_many => 'book', author_id => 'Book']]
      , "$THEME relations: Author has_many Book";

  is_deeply [$schema->list_relations('Book')]
    , [[belongs_to => 'author', author_id => 'Author']]
      , "$THEME relations: Book belongs_to Author";
}

{
  my $THEME = "[many_to_many]";
  my $schema = $CLASS->new
    ([user => undef
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
				      , ['has_many:user_address' => 'user']
				      , ['many_to_many:users'
					 => 'user_address', 'user']
				     ]]]
	       , [primary_key => qw(user address)]]]
	, ['many_to_many:addresses'
	   => 'user_address', 'address']
       ]);

  # print join("", map {chomp;"$_;\n"} $schema->sql_create), "\n";
  foreach my $tabName (qw(user user_address address)) {
    # print terse_dump($schema->list_relations($tabName)), "\n";
  }
}

{
  my $THEME = "[Misc]";
  my $schema = $CLASS->new
    ([Account => undef
      , aid => [int => -primary_key, -autoincrement]
      , aname => [text => -unique]
      , atype => [text => -indexed]]
     # XXX: Enum(Asset, Liability, Income, Expense)

     , [Description => undef
	, did => [int => -primary_key, -autoincrement]
	, dname => [text => -unique]]

     , [Transaction => undef
	, tid => [int => -primary_key, -autoincrement]
	, at =>  [date => -indexed]
	, debit_id => [int => -indexed, ['-belongs_to:debit', 'Account']]
	, amt => 'int'
	, credit_id => [int => -indexed, ['-belongs_to:credit', 'Account']]
	, desc => [int => -indexed, [-belongs_to, 'Description']]
	, note => 'text'
       ]);

  # print join("", map {chomp;"$_;\n"} $schema->sql_create), "\n";
  # print terse_dump($schema->list_relations('Transaction')), "\n";
  # print terse_dump($schema->list_relations('Account')), "\n";
}

{
  my $THEME = "[View (real)]";
  my $schema = $CLASS->new
    ([ticket => undef
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

     , [timeline => {view => <<SQL}
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

  is_deeply [$schema->list_tables], [qw(ticket chng)]
    , "$THEME list_tables";

  is_deeply [$schema->list_views], [qw(timeline)]
    , "$THEME list_views";

  $schema->create(sqlite => $DBNAME);

  is_deeply $schema->dbh->selectall_arrayref
    ('select * from timeline order by at')
      , [[1, ticket => '2010-01-01T09:00', '1st ticket']
	 , [1, chng => '2010-01-01T12:00', '1st chng']
	 , [2, ticket => '2010-01-02T15:00', '2nd ticket']
	 , [2, chng => '2010-01-02T18:00', '2nd chng']
	], "$THEME timeline";
}

# XXX: Should have mysql tests too.
{
  my $THEME = "[trigger_after_delete]";
  my $schema = $CLASS->new
    ([user => {trigger_after_delete => {user_del => <<SQL}}
delete from auth where uid = old.uid
SQL
   , uid => [integer => -primary_key]
   , email => [text => -unique]
   , fullname => [text => -indexed]
   , [-might_have
      , [auth => undef # XXX: {auto_delete => 1}
	 , uid => [integer => -primary_key, [belongs_to => 'user']]
	 , login => [text => -unique]
	 , encpass => 'text'
	 , tmppass => 'text'
	 , tmppass_expire => 'timestamp'
	 , confirm_token => [text => -unique]]]
  ]);

  $schema->create(sqlite => $DBNAME);

  my $dbh = $schema->dbh;

  my @tests
    = ([1, 'foo@example.com', 'Well known foo', 'foo', 'foopass']
       , [2, 'bar@example.com', 'Slightly minor bar', 'bar', 'barpass']);

  foreach my $user (@tests) {
    my ($uid, $email, $full, $login, $pass) = @$user;
    $dbh->do(<<END, undef, $uid, $email, $full);
insert into user(uid, email, fullname) values(?, ?, ?)
END

    $dbh->do(<<END, undef, $uid, $login, $pass); # Not encrypted:-)
insert into auth(uid, login, encpass) values(?, ?, ?)
END

  }

  is_deeply $dbh->selectall_arrayref(<<END)
select user.uid, email, fullname, login, encpass
from user left join auth using(uid) order by user.uid
END
    , \@tests, "Test data is correctly installed";

  $dbh->do('delete from user where uid = ?', undef, 1);

  is_deeply $dbh->selectall_arrayref(<<END)
select uid from user
END
    , [[2]], "uid=1 is removed.";

  is_deeply $dbh->selectall_arrayref(<<END)
select uid from auth
END
    , [[2]], "After deleting uid=1, auth rec is deleted too.";
}

{
  my $schema = $CLASS->new
    ([purchase => undef
      , compid => 'text'
      , prodid => 'text'
      , [primary_key => qw/compid prodid/]]);

  eq_or_diff join("", map {chomp;"$_;\n"} $schema->sql_create)
    , <<END, "multicolumn primary key";
CREATE TABLE purchase
(compid text
, prodid text
, PRIMARY KEY(compid, prodid));
END

  $schema->create(sqlite => $DBNAME);

  my $dbh = $schema->dbh;
  {
    my $ins = $dbh->prepare(<<END);
insert or ignore into purchase(compid, prodid) values(?,?)
END
    $ins->execute('foo', 'bar');
    $ins->execute('foo', 'bar');
    $ins->execute('baz', 'qux');
    $ins->execute('baz', 'qux');
  }

  is_deeply [sort {$$a[0] cmp $$b[0]}
	     @{$dbh->selectall_arrayref('select * from purchase')}]
    , [[qw/baz qux/], [qw/foo bar/]]
      , "multicol primary key insertion";
}

done_testing();
