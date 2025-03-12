## ----------------------------------------------------------------------------
#  t/db-mysql-readdefaultfile.t
# -----------------------------------------------------------------------------
# programmed by Haruka Kataoka, archinet inc.
# (modified from db-mysql.t)
# -----------------------------------------------------------------------------
# (db-mysql.t)
# Mastering programmed by YAMASHINA Hio
#
# Copyright YMIRLINK, Inc.
# -----------------------------------------------------------------------------
# $Id: db-mysql-readdefaultfile.t,v 1.1 2009/07/17 02:51:07 Kataoka Exp Kataoka $
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use File::Spec;

our %DBINFO;
our $configfile;

BEGIN{
	$configfile = File::Spec->rel2abs("tmp$$.cnf");

	%DBINFO = (
		dbname   => $ENV{MYSQL_DBNAME}  || 'test',
		mysql_read_default_file => $configfile,
		mysql_read_default_group => 'tripletail',
	);
};

sub createTestConfigFile {
	my %config = (
		user     => $ENV{MYSQL_USER}    || '',
		password => $ENV{MYSQL_PASS}    || '',
		host     => shift,
		'default-character-set' => shift,
	);

	open my $fh, '>', $configfile;

	print $fh <<EndOfConf;
[client]
user     = "$config{'user'}"
password = "$config{'password'}"
host     = "$config{'host'}"

[tripletail]
default-character-set = "$config{'default-character-set'}"
EndOfConf

	close $fh;
}

END{
	unlink $configfile if -e $configfile;
};

use lib '.';
use t::make_ini {
	ini => {
		TL => {
			trap => 'none',
		},
		DB => {
			type       => 'mysql',
			defaultset => 'DBSET_test',
			DBSET_test => [qw(DBCONN_test)]
		},
		DBCONN_test => \%DBINFO,
	},
};
use Tripletail $t::make_ini::INI_FILE;

my $has_DBD_mysql = eval 'use DBD::mysql;1';
if( !$has_DBD_mysql )
{
	plan skip_all => "no DBD::mysql";
}
my $mysql_version = _mysql_version();
if( !$mysql_version )
{
	plan skip_all => "mysql version check failed";
}
if( $mysql_version < 5.001 )
{
	plan skip_all => "mysql 5.1.x is required, got $mysql_version";
}


# -----------------------------------------------------------------------------
# test spec.
# -----------------------------------------------------------------------------
plan tests => 2 + 2 + 10;

test_connect();  #2.
test_charset();  #2.
test_utf8_kanji();  #10.


# -----------------------------------------------------------------------------
# get mysql version.
# -----------------------------------------------------------------------------
## @rettypr double
sub _mysql_version
{
	my %DBINFO;
	%DBINFO = (
		dbname   => $ENV{MYSQL_DBNAME}  || 'test',
		user     => $ENV{MYSQL_USER}    || '',
		password => $ENV{MYSQL_PASS}    || '',
		host     => $ENV{MYSQL_HOST}    || '',
	);
	my $dsn = "dbi:mysql:dbname=$DBINFO{dbname}";
	$DBINFO{host} and $dsn .= ";host=$DBINFO{host}";
	my $DB = DBI->connect($dsn, $DBINFO{user}, $DBINFO{password}, {
		PrintError => 0,
		RaiseError => 0,
	});
	$DB or return ''; # connect failed.
	my $row = $DB->selectrow_arrayref( q{
		SELECT version()
	});
	my $ver = $row && $row->[0];
	$ver or return ''; # query failed?
	$ver =~ /^(\d+)\.(\d+)\.(\d+)/ or return ''; # invalid format.
	$ver = sprintf('%d.%03d%03d', $1, $2, $3);
	$ver;
};


# -----------------------------------------------------------------------------
# test : 'host' is selected by config file.
# -----------------------------------------------------------------------------
sub test_connect
{
	unlink $configfile if -e $configfile;

	dies_ok {
		$TL->trapError(
			-DB   => 'DB',
			-main => sub{},
		);
	} '[setup] connect failed (no my.cnf file)';

	createTestConfigFile($ENV{MYSQL_HOST} || 'localhost', 'utf8');

	lives_ok {
		$TL->trapError(
			-DB   => 'DB',
			-main => sub{},
		);
	} '[setup] connect ok';
}

sub test_charset
{
	# test whether character set setting is effective.
	my $has_fail;

	# test whether it can switch to 'utf8mb3'
	createTestConfigFile($ENV{MYSQL_HOST} || 'localhost', 'utf8mb3');
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			isa_ok($TL->getDB(), 'Tripletail::DB', '[test_charset/utf8mb3] getDB');
			my $ret = $DB->selectRowArray(q{
				SHOW VARIABLES LIKE 'character_set_client'
			});
			# $ret[0] = ('Variable_name') 'character_set_client'
			# $ret[1] = ('Value') 'utf8mb3'
			if( $ret->[1] ne 'utf8mb3' )
			{
				diag("[test_charset/utf8mb3] client charset could be utf8mb3 but got '$ret->[1]'");
				$has_fail = 1;
			}
		},
	);

	# test whether it can also switch to 'latin1'
	createTestConfigFile($ENV{MYSQL_HOST} || 'localhost', 'latin1');
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			isa_ok($TL->getDB(), 'Tripletail::DB', '[test_charset/latin1] getDB');
			my $ret = $DB->selectRowArray(q{
				SHOW VARIABLES LIKE 'character_set_client'
			});
			# $ret[0] = ('Variable_name') 'character_set_client'
			# $ret[1] = ('Value') 'latin1'
			if( $ret->[1] ne 'latin1' )
			{
				diag("[test_charset/latin1] client charset could be latin1 but got '$ret->[1]'");
				$has_fail = 1;
			}
		},
	);

	if( $has_fail )
	{
		diag('[test_charset] see also: skip-character-set-client-handshake');
	}
}

# -----------------------------------------------------------------------------
# test : 'host' is selected by config file.
# -----------------------------------------------------------------------------
sub test_utf8_kanji
{
	# 'kan ji no ka ra mu mei'.
	my $kanji_column_name = "\xe6\xbc\xa2\xe5\xad\x97\xe3\x81\xae\xe3\x82\xab\xe3\x83\xa9\xe3\x83\xa0\xe5\x90\x8d";
	# 'kan ji no de - ta'.
	my $kanji_data = "\xe6\xbc\xa2\xe5\xad\x97\xe3\x81\xae\xe3\x83\x87\xe3\x83\xbc\xe3\x82\xbf";

	createTestConfigFile($ENV{MYSQL_HOST} || 'localhost', 'utf8');

	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			isa_ok($TL->getDB(), 'Tripletail::DB', '[utf8_kanji] getDB');
			# 'default-character-set' has no effects if
			# 'skip-character-set-client-handshake' is enabled.
			$DB->execute('SET NAMES utf8mb3');

			# create table with kanji column name
			$DB->execute( q{DROP TABLE IF EXISTS tripletail_test;});
			$DB->execute( qq{
				CREATE TABLE tripletail_test
				(
					nval INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
					`$kanji_column_name` TEXT NOT NULL
				) CHARACTER SET utf8;
			});
			pass("[utf8_kanji] create table");

			# insert a kanji value
			$DB->execute( qq{
				INSERT
				  INTO tripletail_test (`$kanji_column_name`)
				VALUES (?)
			}, $kanji_data);
			pass("[utf8_kanji] insert kanji data (bind).");

			# select kanji values
			my $hasharr = $DB->selectAllHash( qq{
				SELECT `$kanji_column_name`
				  FROM tripletail_test
			});
			ok($hasharr, '[utf8_kanji] fetch kanji named column data');
			is($hasharr->[0]->{$kanji_column_name}, $kanji_data, "[utf8_kanji] fetched data is ok");
		},
	);

	# この機能は MySQL 4.1 以降っぽい.
	createTestConfigFile($ENV{MYSQL_HOST} || 'localhost', 'latin1');

	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			isa_ok($TL->getDB(), 'Tripletail::DB', '[utf8_kanji] getDB');
			# 'default-character-set' has no effects if
			# 'skip-character-set-client-handshake' is enabled.
			$DB->execute('SET NAMES latin1');

			# select kanji values
			my $hasharr;
			dies_ok {
				$hasharr = $DB->selectAllHash( qq{
					SELECT `$kanji_column_name`
					  FROM tripletail_test
				});
			} '[utf8_kanji] selecting kanji named column under latin1 setting failed.'
				or diag("got: ".Data::Dumper->new([$hasharr])->Terse(1)->Dump());

			$hasharr = $DB->selectAllArray( qq{
				SELECT *
				  FROM tripletail_test
			});
			is($hasharr->[0]->[0], 1, "[utf8_kanji] fetch ok");
			isnt($hasharr->[0]->[1], $kanji_data, "[utf8_kanji] fetching kanji data under latin1 setting get garbled (1)");
			is($hasharr->[0]->[1], '??????', "[utf8_kanji] fetching kanji data under latin1 setting get garbled (2)");

			$DB->execute( q{DROP TABLE IF EXISTS tripletail_test;});
		},
	);
}

