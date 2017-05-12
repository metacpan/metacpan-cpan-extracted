## --------------------------------------------------------------- -*- perl -*-
#  t/db-pg.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright YMIRLINK, Inc.
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;
use Test::Exception;

our %DBINFO;
BEGIN{
    %DBINFO = (
        dbname   => $ENV{PGSQL_DBNAME}  || 'test',
        user     => $ENV{PGSQL_USER}    || 'postgres',
        password => $ENV{PGSQL_PASS}    || '',
        host     => $ENV{PGSQL_HOST}    || '',
    );
};

use lib '.';
use t::make_ini {
    ini => {
        TL => {
            trap => 'none',
        },
        DB => {
            type       => 'pgsql',
            defaultset => 'DBSET_test',
            DBSET_test => [qw(DBCONN_test)]
        },
        DBCONN_test => \%DBINFO,
    }
};
use Tripletail $t::make_ini::INI_FILE;

my $has_DBD_Pg = eval 'use DBD::Pg;1';
if( !$has_DBD_Pg )
{
	plan skip_all => "no DBD::Pg";
}
if( !$DBINFO{dbname} )
{
	plan skip_all => "no PGSQL_DBNAME";
}
eval {
	local($SIG{__DIE__}) = sub{ die $@ };
	$TL->trapError(
		-DB   => 'DB',
		-main => sub {},
	);
};
if ($@) {
	plan skip_all => "Failed to connect to database: $@";
}

# -----------------------------------------------------------------------------
# test spec.
# -----------------------------------------------------------------------------
plan tests => 1+3+39+25+15+5+2;

&test_setup; #1.
&test_getdb; #3.
&test_misc;  #39.
&test_tx_transaction; #25.
&test_old_transaction;  #15.
&test_locks;  #5.
test_upsert(); #2.

# -----------------------------------------------------------------------------
# test setup.
# -----------------------------------------------------------------------------
sub test_setup
{
	lives_ok {
		$TL->trapError(
			-DB   => 'DB',
			-main => sub{},
		);
	} '[setup] connect ok';
}

# -----------------------------------------------------------------------------
# test getdb.
# -----------------------------------------------------------------------------
sub test_getdb
{
	dies_ok {
		$TL->getDB();
	} '[getdb] getDB without startCgi/trapError';
	
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			isa_ok($TL->getDB(), 'Tripletail::DB', '[getdb] getDB in trapError');
		},
	);
	
	$TL->startCgi(
		-DB => 'DB',
		-main => sub{
			isa_ok($TL->getDB(), 'Tripletail::DB', '[getdb] getDB in startCgi');
			$TL->setContentFilter("t::filter_null");
			$TL->print("test"); # avoid no contents error.
		},
	);
}

# -----------------------------------------------------------------------------
# test misc.
# -----------------------------------------------------------------------------
sub test_misc
{
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			isa_ok($TL->getDB(), 'Tripletail::DB', '[misc] getDB');

            # quote
            is($DB->quote(q{a'b}), q{'a''b'}, '[misc] quote');

            # symquote
            is($DB->symquote(q{a"b}), q{"a""b"}, '[misc] symquote');

            # escapeLike
            is $DB->escapeLike('foo'), 'foo';
            is $DB->escapeLike('f_o'), 'f\\_o';
            is $DB->escapeLike('f%o'), 'f\\%o';
            is $DB->escapeLike('f\\'), 'f\\\\';

            # create a temporary table
            $DB->execute( q{
                CREATE TEMPORARY TABLE tripletail_test
                (
                    nval SERIAL  NOT NULL PRIMARY KEY,
                    sval TEXT    NOT NULL
                )
            });
            pass("[misc] create table");
            $DB->execute(q{SELECT * FROM tripletail_test});
            pass("[misc] SELECT");

            # findTables
            {
                my $sth = $DB->findTables({
                              table => 'tripletail\\_test'
                             });
                isa_ok $sth, 'Tripletail::DB::Sth';

                my $row = $sth->fetchHash;
                isa_ok $row, 'HASH';
                is $row->{TABLE_NAME}, 'tripletail_test';

                my $nonexistent = $sth->fetchHash;
                is $nonexistent, undef;
            }

            # getTableColumns
            {
                my $cols = $DB->getTableColumns('tripletail_test');
                isa_ok $cols, 'ARRAY';

                my @reduced
                  = map {
                      +{ COLUMN_NAME => $_->{ COLUMN_NAME },
                         TYPE_NAME   => $_->{ TYPE_NAME   } };
                    }
                    @$cols;
                is_deeply \@reduced, [ { COLUMN_NAME => 'nval'
                                       , TYPE_NAME   => 'integer'
                                       }
                                     , { COLUMN_NAME => 'sval'
                                       , TYPE_NAME   => 'text'
                                       }
                                     ];

                my $nonexistent = $DB->getTableColumns('********');
                is $nonexistent, undef;
            }

			# insert values.
			$DB->execute( q{
				INSERT
				  INTO tripletail_test (sval)
				VALUES ('apple')
			});
			pass("[misc] insert 'apple' (embeded in sql).");
			foreach my $sval (qw(orange cherry strowberry))
			{
				$DB->execute( q{
					INSERT
					  INTO tripletail_test (sval)
					VALUES (?)
				}, $sval);
				pass("[misc] insert '$sval' (bindvar).");
			}
			
			# check last_insert_id.
			{
				my $seqname = 'tripletail_test_nval_seq';
				my $sth = $DB->execute( q{
					SELECT currval(?)
				}, $seqname);
				ok($sth, '[misc] select lastid');
				my $row1 = $sth->fetchArray();
				is_deeply($row1, [4], '[misc] record is [4]');
				my $row2 = $sth->fetchArray();
				is($row2, undef, '[misc] no second record');
				
				is($DB->getLastInsertId($seqname), 4, '[misc] getLastInsertId()');
				is($DB->getLastInsertId(\'DBSET_test', $seqname), 4, '[misc] getLastInsertId() with dbname');
				SKIP:{
					if( !$DB->getDbh()->can('last_insert_id') )
					{
						skip "[misc] no last_insert_id method", 1;
					}
					is($DB->getDbh()->last_insert_id(undef,undef,undef,undef,{sequence=>$seqname}), 4, '[misc] lastid via dbh last_insert_id');
				};
			}
			
			foreach my $vals ([20, 'plum'],[33, 'melon'],[57,'lychee'] )
			{
				my ($nval, $sval) = @$vals;
				$DB->execute( q{
					INSERT
						INTO tripletail_test (nval, sval)
					VALUES (?, ?)
				}, $nval, $sval);
				pass("[misc] insert ($nval,'$sval').");
			}

            # upsert
            $DB->upsert(
                'tripletail_test',
                {nval => 99},
                {sval => 'rambutan'}
               );
            $DB->upsert(
                'tripletail_test',
                {nval => 99, sval => 'rambutan'},
                {}
               );

			# check valus
			{
				my $sth = $DB->execute( q{
					SELECT nval, sval
					  FROM tripletail_test
					 ORDER BY nval
				});
				ok($sth, '[misc] iterate all');
				foreach my $row (
					[  1, 'apple'      ],
					[  2, 'orange'     ],
					[  3, 'cherry'     ],
					[  4, 'strowberry' ],
					[ 20, 'plum'       ],
					[ 33, 'melon'      ],
					[ 57, 'lychee'     ],
                    [ 99, 'rambutan'   ],
				)
				{
					my ($nval, $sval) = @$row;
					is_deeply($sth->fetchArray(), $row, "[misc] fetch ($nval, $sval)");
				}
				is($sth->fetchArray(), undef, "[misc] fetch undef (terminator)");
			}
		},
	);
}

# -----------------------------------------------------------------------------
# CREATE TABLE test_colors
# -----------------------------------------------------------------------------
sub _create_table_colors
{
	my $DB = shift;
	$DB->execute( q{
		CREATE TEMPORARY TABLE test_colors
		(
			nval SERIAL  NOT NULL PRIMARY KEY,
			sval TEXT    NOT NULL
		)
	});
	foreach my $sval (qw(blue red yellow green aqua cyan))
	{
		$DB->execute( q{
			INSERT
			  INTO test_colors (sval)
			VALUES (?)
		}, $sval);
	}
	+{
		seqname => 'test_colors_nval_seq',
	};
}

# -----------------------------------------------------------------------------
# test tx transaction.
# -----------------------------------------------------------------------------
sub test_tx_transaction
{
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			
			# tx.
			my $tx_works;
			$DB->tx(sub{
				$tx_works = 1;
			});
			ok($tx_works, "[tx_tran] tx works");
			
			my $in_tx;
			is do{
				my $in_tx;
				$DB->tx(sub{ $in_tx = $DB->inTx(); });
			}, 1, "[tx_tran] inTx in tx";
			isnt 1, $DB->inTx(), "[tx_tran] inTx out of tx";
			
			# create test data (blue red yellow green aqua cyan)
			my $tbl = _create_table_colors($DB);
			my $seqname = $tbl->{seqname};
			is $DB->getLastInsertId($seqname), 6, "[tx_tran] lastid";
			is $DB->getLastInsertId(\'DBSET_test', $seqname), 6, "[tx_tran] lastid with dbname";
			{
				my $s = $DB->selectAllHash("SELECT * FROM test_colors");
				is(@$s, 6, '[tx_tran] implicit commit, 6 records in tx');
				$DB->tx(sub{
					$DB->execute("DELETE FROM test_colors WHERE sval = ?", 'yellow');
					$s = $DB->selectAllHash("SELECT * FROM test_colors");
					is(@$s, 5, '[tx_tran] implicit commit, 5 records at end of tx');
				});
				$s = $DB->selectAllHash("SELECT * FROM test_colors");
				is(@$s, 5, '[tx_tran] implicit commit, 5 records after tx');
				
				$DB->tx(sub{
					$DB->execute("DELETE FROM test_colors WHERE sval = ?", 'red');
					$s = $DB->selectAllHash("SELECT * FROM test_colors");
					is(@$s, 4, '[tx_tran] explicit rollback, 4 records in tx');
					$DB->rollback;
				});
				$s = $DB->selectAllHash("SELECT * FROM test_colors");
				is(@$s, 5, '[tx_tran] explicit rollback, 5 records after tx (rollbacked)');
				
				$DB->tx(sub{
					$DB->execute("DELETE FROM test_colors WHERE sval = ?", 'red');
					$s = $DB->selectAllHash("SELECT * FROM test_colors");
					$DB->commit;
				});
				$s = $DB->selectAllHash("SELECT * FROM test_colors");
				is(@$s, 4, '[tx_tran] explicit commit');
				
				eval{ $DB->tx(sub{
					$DB->execute("DELETE FROM test_colors WHERE sval = ?", 'cyan');
					$s = $DB->selectAllHash("SELECT * FROM test_colors");
					is(@$s, 3, '[tx_tran] die implicits rollback, 3 records in tx');
					die "test\n";
				}) };
				is($@, "test\n", "[tx_tran] die in tx");
				$s = $DB->selectAllHash("SELECT * FROM test_colors");
				is(@$s, 4, '[tx_tran] die implicits rollback, 4 records after tx');
			}
			
			# close-wait.
			my $pkg = "Tripletail::DB";
			my $msg = "you can't do anything related to DB after doing rollback or commit in tx";
			foreach my $meth (qw(
				execute
				selectAllHash selectAllArray
				selectRowHash selectRowArray
			)){
				throws_ok {
					$DB->tx(sub{ $DB->commit(); $DB->$meth("SELECT 1"); })
				} qr/^$pkg#$meth: $msg\b/, "[tx_tran] execute on commit close-wait tx";
				throws_ok {
					$DB->tx(sub{ $DB->rollback(); $DB->$meth("SELECT 1"); })
				} qr/^$pkg#$meth: $msg\b/, "[tx_tran] $meth on rollback close-wait tx";
			}
		},
	);
	is($@, '', '[tx_tran] success');
}

# -----------------------------------------------------------------------------
# test old transaction.
# -----------------------------------------------------------------------------
sub test_old_transaction
{
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			
			# begin and commit.
			lives_ok { $DB->begin; }    "[old_tran] begin ok";
			lives_ok { $DB->commit; }   "[old_tran] commit ok";
			
			# begin and rollback.
			lives_ok { $DB->begin; }    "[old_tran] begin ok";
			lives_ok { $DB->rollback; } "[old_tran] rollback ok";
			
			# begin tran within transaction;
			lives_ok { $DB->begin; }    "[old_tran] begin ok";
			dies_ok  { $DB->begin; }    "[old_tran] begin in tran dies";
			lives_ok { $DB->rollback; } "[old_tran] rollback ok";
			
			# begin/rollback w/o transaction.
			dies_ok { $DB->commit; }   "[old_tran] commit w/o transaction dies";
			dies_ok { $DB->rollback; } "[old_tran] rollback w/o transaction dies";
			
			# create test data.
			_create_table_colors($DB);
			
			# check whether rollback works.
			is($DB->selectRowHash(q{SELECT COUNT(*) AS cnt FROM test_colors})->{cnt}, 6, "[old_tran] test table contains 6 records");
			lives_ok { $DB->begin; } "[old_tran] begin";
			lives_ok { $DB->execute("DELETE FROM test_colors"); } "[old_tran] delete all";
			is($DB->selectRowHash(q{SELECT COUNT(*) AS cnt FROM test_colors})->{cnt}, 0, "[old_tran] test table contains no records");
			lives_ok { $DB->rollback; } "[old_tran] rollback";
			is($DB->selectRowHash(q{SELECT COUNT(*) AS cnt FROM test_colors})->{cnt}, 6, "[old_tran] test table contains 6 records");
		},
	);
}

# -----------------------------------------------------------------------------
# test locks.
# -----------------------------------------------------------------------------
sub test_locks
{
	$TL->trapError(
		-DB => 'DB',
		-main => sub{
			my $DB = $TL->getDB();
			_create_table_colors($DB);
			
			my $not_supported = sub{
				my $func = shift;
				my $type = 'pgsql';
				"Tripletail::DB#lock: DB type [$type] is not supported. (DB type [$type] に対する $func はサポートされていません)";
			};
			my $lock_not_supported_msg   = $not_supported->('lock');
			my $unlock_not_supported_msg = $not_supported->('unlock');
			lives_ok { $DB->execute(q{SELECT COUNT(*) FROM test_colors}) } "[locks] table test_colors exists";
			throws_ok { $DB->lock(read=>'test_colors') } qr/\Q$lock_not_supported_msg/, "[locks] lock test_colors: not supported";
			
			throws_ok { $DB->lock } qr/Tripletail::DB#lock: no tables are being locked. Specify at least one table./, "[locks] lock no tables";
			throws_ok { $DB->unlock } qr/Tripletail::DB#unlock: no tables are locked/, "[locks] unlock: not locked";
			throws_ok { $DB->unlock } qr/Tripletail::DB#unlock: no tables are locked/, "[locks] unlock w/o lock";
			
		},
	);
}

# -----------------------------------------------------------------------------
# UPSERT
# -----------------------------------------------------------------------------
sub test_upsert {
    $TL->trapError(
        -DB   => 'DB',
        -main => sub {
            my $DB = $TL->getDB;

            $DB->execute(q{
                CREATE TEMPORARY TABLE tl_upsert_test (
                    key1 INTEGER,
                    key2 INTEGER,
                    val3 INTEGER,

                    PRIMARY KEY (key1, key2)
                )
            });

            $DB->upsert(
                \'DBSET_test',
                'tl_upsert_test',
                {key1 => 0, key2 => 0},
                {val3 => undef});
            {
                my $rows = $DB->selectAllHash(
                               'SELECT * FROM tl_upsert_test');
                is_deeply $rows, [ {key1 => 0, key2 => 0, val3 => undef } ];
            }

            $DB->upsert(
                'tl_upsert_test',
                {key1 => 0, key2 => 0},
                {val3 => undef});
            {
                my $rows = $DB->selectAllHash(
                               'SELECT * FROM tl_upsert_test');
                is_deeply $rows, [ {key1 => 0, key2 => 0, val3 => undef } ];
            }
        });
}
