#!/usr/bin/perl -w

use Tiger;

sub do_test {
  my ($label, $str, $expect) = @_;
  my ($tiger);

  $tiger = new Tiger;

  $tiger->add($str);
  print "$label: ($str)\nEXPECT:   $expect\n";
  print "RESULT 1: " . $tiger->hexdigest() . "\n";
  print "RESULT 2: " . $tiger->hexhash($str) . "\n";
}

do_test("test1", "", 
	"24f0130c63ac9332 16166e76b1bb925f f373de2d49584e7a");
do_test("test2", "abc", 
	"f258c1e88414ab2a 527ab541ffc5b8bf 935f7b951c132951");
do_test("test3", "Tiger",
	"9f00f599072300dd 276abb38c8eb6dec 37790c116f9d2bdf");
do_test("test4", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-",
	"87fb2a9083851cf7 470d2cf810e6df9e b586445034a5a386");
do_test("test5", "ABCDEFGHIJKLMNOPQRSTUVWXYZ=abcdefghijklmnopqrstuvwxyz+0123456789",
	"467db80863ebce48 8df1cd1261655de9 57896565975f9197");
do_test("test6", "Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham",
	"0c410a042968868a 1671da5a3fd29a72 5ec1e457d3cdb303");
do_test("test7", "Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham, proceedings of Fast Software Encryption 3, Cambridge, 1996.",
	"3d9aeb03d1bd1a63 57b2774dfd6d5B24 dd68151d503974fC");
do_test("test8", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-",
	"00b83eb4e53440c5 76ac6aaee0a74858 25fd15e70a59ffe4");
