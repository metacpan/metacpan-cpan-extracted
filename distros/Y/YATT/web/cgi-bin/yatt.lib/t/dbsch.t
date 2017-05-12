#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Test::More;
use Test::Differences;

use FindBin;
use lib "$FindBin::Bin/..";

foreach my $req (qw(DBD::SQLite SQL::Abstract)) {
  unless (eval qq{require $req}) {
    plan skip_all => "$req is not installed."; exit;
  }
}
plan qw(no_plan);

use YATT::Util::Finalizer;

ok chdir($FindBin::Bin), "chdir to testdir";

my $CLS = 'YATT::DBSchema';
my $MEMDB = ':memory:';
require_ok($CLS);

sub raises (&@) {
  my ($test, $errPat, $title) = @_;
  eval {$test->()};
  Test::More::like $@, $errPat, $title;
}

sub trim ($) {my $text = shift; $text =~ s/\n\Z//; $text}

sub cat {
  my ($fn) = @_;
  open my $fh, '<', $fn or die "$fn: $!";
  chomp(my @all = <$fh>);
  wantarray ? @all : \@all;
}

# use 抜きの、素の YATT::DBSchema->create を試す。

my @test1 = ($ENV{DEBUG} ? (-verbose) : ()
	     , -auto_create
	     , [foo => []
		, [foo_id => 'integer'
		   , -primary_key, -auto_increment]
		, [foo => 'varchar(80)', -indexed]
		, [bar_id => [bar => []
			      , [bar_id => 'integer'
				 , -primary_key, -auto_increment]
			      , [bar => 'varchar(80)', -unique]]]
		, [baz => 'varchar(80)']]);

{
  my $schema = $CLS->define(@test1);

  eq_or_diff scalar $schema->sql_create(dbtype => 'sqlite')
    , trim <<END, "sql_create dbtype=sqlite";
CREATE TABLE foo
(foo_id integer primary key
, foo varchar(80)
, bar_id int
, baz varchar(80));
CREATE INDEX foo_foo on foo(foo);
CREATE TABLE bar
(bar_id integer primary key
, bar varchar(80) unique)
END

  eq_or_diff scalar $schema->sql_create(dbtype => 'mysql')
    , trim <<END, "sql_create dbtype=mysql";
CREATE TABLE foo
(foo_id integer primary key auto_increment
, foo varchar(80)
, bar_id int
, baz varchar(80));
CREATE INDEX foo_foo on foo(foo);
CREATE TABLE bar
(bar_id integer primary key auto_increment
, bar varchar(80) unique)
END

  eq_or_diff scalar $schema->sql(qw(insert foo)), <<END, "sql insert foo";
INSERT INTO foo(foo, bar_id, baz)
values(?, ?, ?)
END
  eq_or_diff scalar $schema->sql(qw(select foo)), trim <<END, "sql select foo";
SELECT foo_id, foo, foo.bar_id, bar_id.bar, baz FROM foo
LEFT JOIN bar bar_id on foo.bar_id = bar_id.bar_id
END
  eq_or_diff scalar $schema->sql(qw(update bar bar))
    , trim <<END, "sql update bar bar";
UPDATE bar SET bar = ? WHERE bar_id = ?
END

  #========================================

  raises {$schema->connect_to(foo => 'bar')}
    qr{^YATT::DBSchema: Unknown dbtype: foo}
      , "Unknown dbtype";

}

# t/test-mysql.pass should contain
# * dbname=$mysql_dbname
# * $user
# * $pass

SKIP:
foreach my $dbspec ([undef, sqlite => $MEMDB, 'w']
		    , ["test-mysql.dsn", dbi => 'dbi:mysql']) {
  my ($passfn, @spec) = @$dbspec;
  if (defined $passfn) {
    skip "DSN not configured: $passfn", 8 unless -r $passfn;
    my ($dbiarg, $user, $pass) = my @lines = cat($passfn);
    ok @lines >= 3, "DSN has enough lines";
    $spec[1] .= ":$dbiarg";
    @spec[2,3] = ($user, $pass);
  }
  my $schema = $CLS->define(@test1);

  $schema->connect_to(@spec);
  if (defined $passfn) {
    $schema->drop;
    $schema->create;
  }

  my $ins = $schema->to_insert('foo');
  $ins->('FOOx', 'AAA', 'BAZ');
  my $test_foo = sub {
    $schema->dbh->selectall_arrayref(<<END)
select foo, bar, baz from foo left join bar using(bar_id)
END
  };
  is_deeply $test_foo->()
    , [['FOOx', 'AAA', 'BAZ']], "[@spec[0,1]]. 1 row inserted.";

  $ins->('fooy', 'AAA', 'baz');
  $ins->('Fooz', 'bbb', 'baz');

  is_deeply $test_foo->()
    , [['FOOx', 'AAA', 'BAZ']
       , ['fooy', 'AAA', 'baz']
       , ['Fooz', 'bbb', 'baz']], "[@spec[0,1]]. and 2 rows inserted.";

  is_deeply $schema->to_fetch
    (foo => [qw(foo bar baz)]
     , where => {bar => 'bbb'})->fetchall_arrayref
       , [['Fooz', 'bbb', 'baz']]
	 , "[@spec[0,1]]. to_fetch->fetchall_arrayref where {bar => 'bbb'}";

  is_deeply $schema->to_select
    (foo => [qw(foo bar baz)]
     , where => {bar => 'bbb'})->()
       , [['Fooz', 'bbb', 'baz']]
	 , "[@spec[0,1]]. to_select()->() where {bar => 'bbb'}";

  is_deeply $schema->select
    (foo => [qw(foo bar baz)]
     , hashref => 1, limit => 1, order_by => 'foo_id desc')
      , {foo => 'Fooz', bar => 'bbb', baz => 'baz'}
        , "[@spec[0,1]]. select hashref {}";

  is_deeply $schema->select
    (foo => [qw(foo bar baz)]
     , arrayref => 1, limit => 1, order_by => 'foo_id desc')
      , ['Fooz', 'bbb', 'baz']
        , "[@spec[0,1]]. select arrayref []";

  {
    my $id = $schema->select(foo => foo_id =>
			     where => {foo => 'Fooz'})->[0];
    $schema->to_update(foo => 'baz')->("bazzzz", $id);
    is_deeply $schema->select(foo => 'baz'
			     , where => {foo => 'Fooz'})->[0], "bazzzz"
      , "[@spec[0,1]]. update foo baz=bazzzz";
  }

  $schema->drop;
  $schema->dbh->commit;
}

# import and run

{
  {
    package dbsch_test;
    $CLS->import(-as_base
		 , connection_spec => [sqlite => ':memory:', 'w']
		 , [foo => []
		    , [foo => 'varchar', -indexed]
		    , [bar_id => [bar => []
				  , [bar_id => 'integer', -primary_key]
				  , [bar => 'varchar', -unique]]]
		    , [baz => 'varchar']]);
  }
  raises {dbsch_test->run} qr{^Usage: dbsch.t method args..}, "run help";
  eq_or_diff capture {dbsch_test->run(select => 'foo')}, <<END, "run select";
foo\tbar_id\tbar\tbaz
END

  eq_or_diff capture {
    dbsch_test->run(sql => select => 'foo')
  }, <<END, "run sql select";
SELECT foo, foo.bar_id, bar_id.bar, baz FROM foo
LEFT JOIN bar bar_id on foo.bar_id = bar_id.bar_id
END
}

{
  my $tz = 3600*(localtime 0)[2];
  is $CLS->ymd_hms(0 - $tz), '1970-01-01 00:00:00', 'ymd_hms localtime';
  is $CLS->ymd_hms(0, 1), '1970-01-01 00:00:00', 'ymd_hms utc';
}
