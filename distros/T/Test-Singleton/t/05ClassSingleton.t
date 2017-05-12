#!/usr/bin/perl

use Test::Builder::Tester tests => 2;
use Test::More;
use Data::Dumper;
use lib qw( lib );

use_ok( 'Test::Singleton' );

# expected output of below is_singleton test
test_out("ok 1 - require Class::Singleton;\n" . 
	 "ok 2 - instance of object created\n" .
	 "ok 3 - instance of object created\n".
	 "ok 4 - is singleton");

is_singleton( 'Class::Singleton', "instance", "instance" );

test_test('Class::Singleton is a singleton class');
 










