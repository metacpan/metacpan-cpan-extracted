#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 31;

use_ok ('File::Temp');

my $dbfile_fh = File::Temp->new(UNLINK => 1);
my $dbfile = $dbfile_fh->filename;

ok(defined($dbfile),"temp db file is ".$dbfile);

my $sqlite_init = "dbi:SQLite:dbname=$dbfile";

use_ok('DBI');
my $dbh = DBI->connect($sqlite_init,"","",{RaiseError => 1});

ok($dbh->do('CREATE TABLE testtable ( id INTEGER PRIMARY KEY, text TEXT NULL)'),'Create test table');
ok($dbh->do('INSERT INTO testtable(id,text) VALUES(1,"item 1")'),'Create test row');

eval {
	package local::DB::Result::testtable;
	use base qw/DBIx::Class::Core/;
	__PACKAGE__->table('testtable');
	__PACKAGE__->add_columns('id','text');
	__PACKAGE__->set_primary_key('id');

	package local::DB;
	use base qw/DBIx::Class::Schema/;
	__PACKAGE__->load_namespaces;

	package main;
};

use_ok( 'Tie::DBIx::Class' );

my $schema = local::DB->connect($sqlite_init,'','');
ok(defined($schema),'DBIx::Class init complete');
ok($schema->register_class('testtable','local::DB::Result::testtable'),'Register testtable');
my $rs = $schema->resultset('testtable')->find(1);
ok(defined($rs),'ResultSet defined');

ok(tie(my %test,'Tie::DBIx::Class',$schema,'testtable',1),'tie');
like(tied(%test),qr/^\QTie::DBIx::Class=HASH(\E/,'Check tied');
is($test{id},1,'Check primary key');
is($test{text},'item 1','Check column');

ok(exists($test{id}),'Exists key');
ok(exists($test{text}),'Exists column');
ok(!exists($test{notexist}),'Exists invalid column');

is_deeply([sort(keys(%test))],['id','text'],'keys()');

delete $test{text};
is($test{text},undef,'Deleted value');

ok(untie( %test),'untie');
undef %test;

ok(tie(%test,'Tie::DBIx::Class',$schema,'testtable',undef),'tie new row');
ok($test{id} = 2,'Set new primary key');
ok($test{text} = '2nd item','Set new column');
is($test{id},2,'Check new primary key');
is($test{text},'2nd item','Check new column');
ok(untie( %test),'untie new row');
undef %test;
is($test{id},undef,'Check untied primary key');
is($test{text},undef,'Check untied row');

ok(tie(%test,'Tie::DBIx::Class',$schema,'testtable',2),'tie created row');
is($test{id},2,'Check created primary key');
is($test{text},'2nd item','Check created column');
ok(untie( %test),'untie created row');
undef %test;
