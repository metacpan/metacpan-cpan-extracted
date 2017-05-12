# -*- perl -*-
use Test::More;
use Test::Exception;
use strict;
use warnings;

use lib '.';
use t::make_ini {
	ini => sub{+{
		TL => {
			trap => 'none',
		},
		DB => {
			type       => 'mysql',
			defaultset => 'SET_Default',
			SET_Default => [qw(DBCONN_test)]
		},
		DBCONN_test => {
			host   => 'localhost',
			user   => $t::make_ini::USER,
			dbname => 'test',
		},
	};},
};
use Tripletail $t::make_ini::INI_FILE;

eval { require DBD::mysql; 1; };
$@ and plan skip_all => "no DBD::mysql";

eval {
    $TL->trapError(
	-DB   => 'DB',
	-main => sub {},
       );
};
if ($@) {
	plan skip_all => "Failed to connect to local MySQL: $@";
}

plan tests => 66+24+15;

&test_mysql; #66.
&test_tx_transaction; #24.
&test_old_transaction;  #15.

sub test_mysql
{
	dies_ok {$TL->getDB} '_getInstance die';
	
	$TL->trapError(
		-DB   => 'DB',
		-main => \&main,
	);
}
sub main {

    my $DB;
	dies_ok {$TL->getDB(\123)} '_getInstance die';
	ok($DB = $TL->newDB('DB'), 'newDB');
	ok($DB->connect, 'connect');
	ok($DB->disconnect, 'disconnect');
	
    ok($DB = $TL->getDB, 'getDB');
    ok($DB = $TL->getDB('DB'), 'getDB');
    dies_ok {$DB->begin(\123)} 'getDB die';
    dies_ok {$DB->begin('getDB')} 'getDB die';

    dies_ok {$DB->rollback} 'rollback die';
    dies_ok {$DB->commit} 'commit die';
    dies_ok {$DB->unlock} 'unlock die';
    $DB->begin('SET_Default');
    dies_ok {$DB->begin('SET_Default')} 'begin die';
    $DB->commit;
    dies_ok {$DB->execute} 'execute die';
    dies_ok {$DB->execute(\123,\123)} 'execute die';
    dies_ok {$DB->execute(q{ LOCK })} 'execute die';
    dies_ok {$DB->execute(q{??})} 'execute die';
    dies_ok {$DB->execute(q{ LOCK })} 'execute die';
    dies_ok {$DB->setBufferSize(\123)} 'setBufferSize die';
    dies_ok {$DB->symquote} 'symquote die';
    dies_ok {$DB->symquote(\123)} 'symquote die';
	is($DB->symquote('a b c'), '`a b c`', 'symquote');

    ok($DB->begin('SET_Default'), 'begin');
    ok($DB->execute('SHOW TABLES'), 'execute');
    ok($DB->rollback, 'rollback');

	$DB->begin('SET_Default');
	# 注意: テストスクリプトを二つ同時に走らせるとおかしくなる。
	$DB->execute(q{
        DROP TABLE IF EXISTS TripletaiL_DB_Test
    });
	$DB->execute(q{
        CREATE TABLE TripletaiL_DB_Test (
            foo   BLOB,
            bar   BLOB,
            baz   BLOB
        )
    });
	$DB->commit;

    ok($DB->execute('SHOW TABLES'), 'execute w/o transaction');
    ok($DB->setDefaultSet('SET_Default'), 'setDefaultSet');
    ok($DB->execute('SHOW TABLES'), 'execute w/o transaction');

	dies_ok {$DB->execute(
		\'die' => q{
        INSERT INTO TripletaiL_DB_Test
               (foo, bar, baz)
        VALUES (?,   ?,   ?  )
    }, 'QQQ', 'WWW', 'EEE')} 'execute die';

	ok($DB->execute(
		\'SET_Default' => q{
        INSERT INTO TripletaiL_DB_Test
               (foo, bar, baz)
        VALUES (?,   ?,   ?  )
    }, 'QQQ', 'WWW', 'EEE'), 'execute with explicit DBSet');

	ok($DB->execute(q{
		SELECT *
          FROM TripletaiL_DB_Test
         LIMIT ??
    }, [1, 2, \'SQL_INTEGER']), 'execute with fully typed parameters');

#	ok($DB->execute(q{
#		SELECT *
#        FROM TripletaiL_DB_Test
#         LIMIT ??
#   }, 123), 'execute with fully typed parameters');

    dies_ok {$DB->execute(q{
		SELECT *
          FROM TripletaiL_DB_Test
	LIMIT ??
    },123)} 'execute die';

    dies_ok {$DB->execute(q{
		SELECT *
          FROM TripletaiL_DB_Test
	LIMIT ??
    },\1)} 'execute die';

    dies_ok {$DB->execute(q{
		SELECT *
          FROM TripletaiL_DB_Test
    },[\1])} 'execute die';

    dies_ok {$DB->execute(q{
		SELECT *
         FROM TripletaiL_DB_Test
	LIMIT ??
    },[])} 'execute die';

	my $insertsth;
	ok($insertsth = $DB->execute(q{
        INSERT INTO TripletaiL_DB_Test
               (foo, bar)
        VALUES (??)
    }, [1, [2, \'SQL_VARCHAR']]), 'execute with partly typed parameters');
	is($insertsth->ret, 1, 'execute return value');
	
	ok($DB->execute(q{
        INSERT INTO TripletaiL_DB_Test
               (foo, bar)
        VALUES (??)
    }, [3, [4, \'SQL_VARCHAR'], \'SQL_INTEGER']), 'execute with both partly and fully typed parameters');

	my $array;
	ok($array = $DB->selectAllHash(q{
        SELECT *
          FROM TripletaiL_DB_Test
    }), 'selectAllHash');
	is_deeply($array, [
		{foo => 'QQQ', bar => 'WWW', baz => 'EEE'},
		{foo => 1,     bar => 2,     baz => undef},
		{foo => 3,     bar => 4,     baz => undef},
	   ], 'content of selectAllHash()');

	ok($array = $DB->selectAllArray(q{
        SELECT *
          FROM TripletaiL_DB_Test
         WHERE foo = ?
    }, 'QQQ'), 'selectAllArray');
	is_deeply($array, [['QQQ', 'WWW', 'EEE']], 'content of selectAllArray()');

	is_deeply($DB->selectRowHash(q{
		SELECT *
		  FROM TripletaiL_DB_Test
	}), {foo => 'QQQ', bar => 'WWW', baz => 'EEE'}, 'selectRowHash');
	is_deeply($DB->selectRowHash(q{
		SELECT *
		  FROM TripletaiL_DB_Test
		 WHERE 0
	}), undef, 'selectRowHash, no-record becomes empty hashref');

	is_deeply($DB->selectRowArray(q{
		SELECT *
		  FROM TripletaiL_DB_Test
        }), ['QQQ', 'WWW', 'EEE'], 'selectRowArray');

	is_deeply($DB->selectRowArray(q{
		SELECT *
		  FROM TripletaiL_DB_Test
		 WHERE 0
	}), undef, 'selectRowArray, no-record becomes empty arrayref');

	ok($DB->lock(read => 'TripletaiL_DB_Test'), 'lock');
	dies_ok {$DB->lock(read => 'TripletaiL_DB_Test')} 'lock die';

	ok($DB->unlock, 'unlock');

	ok($DB->lock(set => 'SET_Default', read => 'TripletaiL_DB_Test'), 'lock with DBSet');
	$DB->unlock;

	ok($DB->setBufferSize(0), 'setBufferSize');

	is($DB->symquote('a b c'), '`a b c`', 'symquote');
	
    is($DB->getType, 'mysql', 'getType');

	is(ref($DB->getDbh), 'DBI::db', 'getDbh');

	my $sth = $DB->execute(q{
        SELECT *
          FROM TripletaiL_DB_Test
    });
	
	my $hash;
	ok($hash = $sth->fetchHash, 'fetchHash');
	is_deeply($hash, {foo => 'QQQ', bar => 'WWW', baz => 'EEE'}, 'content of fetchHash()');

	ok($array = $sth->fetchArray, 'fetchArray');
	is_deeply($array, [1, 2, undef], 'content of fetchArray()');

	1 while $sth->fetchArray;
	is($sth->rows, 3, 'rows');

	is_deeply($sth->nameArray, ['foo', 'bar', 'baz'], 'nameArray');
	is_deeply($sth->nameHash, {foo => 0, bar => 1, baz => 2}, 'nameHash');


    $DB->setBufferSize(1);

    $DB->execute(\'SET_Default' => q{
        INSERT INTO TripletaiL_DB_Test
               (foo, bar, baz)
        VALUES (?,   ?,   ?  )
    }, 'QQQQQ', 'WWWWW', 'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE');

    $sth = $DB->execute(q{
        SELECT *
          FROM TripletaiL_DB_Test
    });
    ok($hash = $sth->fetchHash, 'fetchHash');
    is_deeply($hash, {foo => 'QQQ', bar => 'WWW', baz => 'EEE'}, 'content of fetchHash()');

    $sth = $DB->execute(q{
        SELECT *
          FROM TripletaiL_DB_Test
    });
    ok($hash = $sth->fetchArray, 'fetchArray');

    $sth = $DB->execute(q{
        SELECT *
          FROM TripletaiL_DB_Test
        WHERE foo = ?
    },'QQQQQ');
    dies_ok {$hash = $sth->fetchHash} 'fetchHash die';

    $sth = $DB->execute(q{
        SELECT *
          FROM TripletaiL_DB_Test
        WHERE foo = ?
    },'QQQQQ');
    dies_ok {$hash = $sth->fetchArray} 'fetchArray die';

	$sth->finish;

	$DB->execute(q{
        DROP TABLE TripletaiL_DB_Test
    });
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
			nval INT      NOT NULL PRIMARY KEY AUTO_INCREMENT,
			sval TINYBLOB NOT NULL
		) Engine=innodb
	});
	foreach my $sval (qw(blue red yellow green aqua cyan))
	{
		$DB->execute( q{
			INSERT
			  INTO test_colors (sval)
			VALUES (?)
		}, $sval);
	}
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
			_create_table_colors($DB);
			is $DB->getLastInsertId(), 6, "[tx_tran] lastid";
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
			is($DB->selectRowHash(q{SELECT COUNT(*) cnt FROM test_colors})->{cnt}, 6, "[old_tran] test table contains 6 records");
			lives_ok { $DB->begin; } "[old_tran] begin";
			lives_ok { $DB->execute("DELETE FROM test_colors"); } "[old_tran] delete all";
			is($DB->selectRowHash(q{SELECT COUNT(*) cnt FROM test_colors})->{cnt}, 0, "[old_tran] test table contains no records");
			lives_ok { $DB->rollback; } "[old_tran] rollback";
			is($DB->selectRowHash(q{SELECT COUNT(*) cnt FROM test_colors})->{cnt}, 6, "[old_tran] test table contains 6 records");
		},
	);
}
