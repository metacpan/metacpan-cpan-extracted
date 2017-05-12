#!perl

use Test::More tests => 15;

my $have_db = 1;

eval "use DBI";

$have_db = 0 if $@;

SKIP: {
	skip "DBI is not installed", 15 unless $have_db;
	
	my $dbh;
    eval {
        $dbh = DBI->connect("DBI:mysql:host=127.0.0.1:db=test","root","");
    };

 	skip "Cannot connect properly", 15 unless defined $dbh;
	
	$dbh->do("DROP TABLE IF EXISTS www_session_test_table");

	$dbh->do("
		CREATE TABLE `www_session_test_table` (
		  `id` int(11) unsigned NOT NULL auto_increment,
		  `sid` varchar(32) NOT NULL default '',
		  `data` text NOT NULL,
		  `created` timestamp NOT NULL default CURRENT_TIMESTAMP,
		  `expires` timestamp NOT NULL default '0000-00-00 00:00:00',
		  PRIMARY KEY  (`id`),
		  UNIQUE KEY `sid` (`sid`)
		) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
	");
	
	use_ok('WWW::Session::Storage::MySQL');

	my $storage = WWW::Session::Storage::MySQL->new({
							dbh => $dbh,
							table => "www_session_test_table",
							fields => {
								sid => 'sid',
								data => 'data',
								expires => 'expires'
							}
					});

	{	
		my $sid = 'test1';
		my $expires = -1;
		my $string = "Test 123";

		ok($storage->save($sid,$expires,$string),'Save works');

		sleep 1;

		my $rstring = $storage->retrieve($sid);

		is($rstring,$string,"String preserved");

		$storage->delete($sid);
		
		$rstring = $storage->retrieve($sid);
		is($rstring,undef,"Session data removed after destory()");
	}

	{
		my $sid = 'test2';
		my $expires = 10;
		my $string = "Test 123";

		ok($storage->save($sid,$expires,$string),'Save2 works');

		sleep 1;

		my $rstring = $storage->retrieve($sid);

		is($rstring,$string,"String2 preserved");

		$storage->delete($sid);
		
		$rstring = $storage->retrieve($sid);
		is($rstring,undef,"Session data removed after destory()");
	}


	{
		my $sid = 'test3';
		my $expires = 1;
		my $string = "Test 123";

		ok($storage->save($sid,$expires,$string),'Save3 works');

		sleep 3;

		my $rstring = $storage->retrieve($sid);

		is($rstring,undef,"String3 expired before we retrieved it");
	}

	{#utf8 test
		my $sid = 'test4';
		my $expires = 1;
		my $string = "Test 123 îâăȚȘș";

		ok($storage->save($sid,$expires,$string),'Save4 works');

		my $rstring = $storage->retrieve($sid);

		is($rstring,'Test 123 îâăȚȘș',"String4 (utf8) preserved");

		$storage->delete($sid);
		$rstring = $storage->retrieve($sid);
		is($rstring,undef,"Session data removed after destory()");
	}
	
	
	{#db cleanup
		my $sid = 'random_session_id_'.int(rand(100));
		
		my $rstring = $storage->retrieve($sid);

		is($rstring,undef,"Random session does not exist");
		
		ok($storage->save($sid,1,'bla'),'Save5 works');
		
		sleep 3;
		
		$storage->_reset_last_cleanup; #reset last cleanup counter
		
		is($storage->retrieve('abcd'),undef,'random key does not exist');#supposed to clean up $sid since it expired
		
		my $sth = $dbh->prepare("select * from www_session_test_table");
		$sth->execute();
		while (my $db_entry = $sth->fetchrow_arrayref) {		    
		    ok(0,"Session ".$db_entry->[1]." exipred at ".$db_entry->[2]." but was cleaned up");
		}
	}
	
	$dbh->do("DROP TABLE www_session_test_table");
}