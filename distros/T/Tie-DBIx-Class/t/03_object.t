#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 14;

use_ok ('File::Temp');

my $dbfile_fh = File::Temp->new(UNLINK => 1);
my $dbfile = $dbfile_fh->filename;

ok(defined($dbfile),"temp db file is ".$dbfile);

my $sqlite_init = "dbi:SQLite:dbname=$dbfile";

use_ok('DBI');
my $dbh = DBI->connect($sqlite_init,"","",{RaiseError => 1});

ok($dbh->do('CREATE TABLE testtable ( id INTEGER PRIMARY KEY, text TEXT NOT NULL)'),'Create test table');
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

	package local::Obj;
	
	sub new {
		my $class = shift;
		my $schema = shift;

		tie(my %test,'Tie::DBIx::Class',$schema,'testtable',1);
		return bless \%test,$class;

	}

	sub answer {
		return 42;
	}

	sub check_text {
		my $self = shift;
		return $self->{text};
	}

	package main;
};

use_ok( 'Tie::DBIx::Class' );

my $schema = local::DB->connect($sqlite_init,'','');
ok(defined($schema),'DBIx::Class init complete');
ok($schema->register_class('testtable','local::DB::Result::testtable'),'Register testtable');
my $rs = $schema->resultset('testtable')->find(1);
ok(defined($rs),'ResultSet defined');

my $obj = local::Obj->new($schema);
ok(defined($obj),'Object created');
is($obj->{id},1,'Check primary key');
is($obj->{text},'item 1','Check column');

is($obj->answer,42,'Check object method');
is($obj->check_text,'item 1','Check object method with database access');
