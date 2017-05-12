#!perl

use Test::More tests => 16;

use_ok('WWW::Session::Storage::File');

my $storage = WWW::Session::Storage::File->new({path => "."});

{
	my $sid = 'test1';
	my $expires = -1;
	my $string = "Test 123";
	
	ok($storage->save($sid,$expires,$string),'Save works');
	
	sleep 1;
	
	my $rstring = $storage->retrieve($sid);
	
	is($rstring,$string,"String preserved");
	ok(-f $sid,"File 1 still exists");

	$storage->delete($sid);
	ok(! -f $sid,"File 1 removed after destory");
}

{
	my $sid = 'test2';
	my $expires = 10;
	my $string = "Test 123";
	
	ok($storage->save($sid,$expires,$string),'Save2 works');
	
	sleep 1;
	
	my $rstring = $storage->retrieve($sid);
	
	is($rstring,$string,"String2 preserved");
	ok(-f $sid,"File 2 still exists");
	
	$storage->delete($sid);
	ok(! -f $sid,"File 2 removed after destory");
}


{
	my $sid = 'test3';
	my $expires = 1;
	my $string = "Test 123";
	
	ok($storage->save($sid,$expires,$string),'Save3 works');
	
	sleep 3;
	
	my $rstring = $storage->retrieve($sid);
	
	is($rstring,undef,"String3 preserved");
	ok(! -f $sid,"File 3 removed");
}

{#utf8 test
	my $sid = 'test4';
	my $expires = 1;
	my $string = "Test 123 îâăȚȘș";
	
	ok($storage->save($sid,$expires,$string),'Save4 works');
	
	my $rstring = $storage->retrieve($sid);
	
	is($rstring,'Test 123 îâăȚȘș',"String4 (utf8) preserved");
	ok(-f $sid,"File 4 still exists");
	
	$storage->delete($sid);
	ok(! -f $sid,"File 4 removed after destory");
}