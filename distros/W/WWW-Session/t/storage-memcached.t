#!perl

use Test::More tests => 13;

my $have_memcache = 1;

eval "use Cache::Memcached";

$have_memcache = 0 if $@;

SKIP: {
	skip "Cache::Memcached is not installed", 13 unless $have_memcache;
	
	use_ok('WWW::Session::Storage::Memcached');

	my $storage = WWW::Session::Storage::Memcached->new({servers => ["127.0.0.1:11211"]});
	
	skip "Memcached server is not running on 127.0.0.1:11211", 12 unless $storage->{memcached}->set('www_session_test','123',1);

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

		is($rstring,undef,"String3 preserved");
		
		$rstring = $storage->retrieve($sid);
		is($rstring,undef,"Session data removed after destory()");
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
	
}