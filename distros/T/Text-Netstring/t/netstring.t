# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# $Id: netstring.t,v 1.7 2006/11/20 18:17:11 james Exp $

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Netstring qw(netstring_encode netstring_decode netstring_verify);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $string;
my @list;


#
# test 2; encode a string into a netstring
# bing-bang-a-bang  should become  16:bing-bang-a-bang,
#
$string = netstring_encode("bing-bang-a-bang");
if ($string eq "16:bing-bang-a-bang,") {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}


#
# test 3; verify a valid netstring
# the result of above should verify as a netstring
#
if (netstring_verify($string)) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}


#
# test 4; verify invalid netstrings
#
CASE: {
	netstring_verify("bing-bang-a-bang") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify(":bing-bang-a-bang") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify(":bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("15:bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("17:bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("1:bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("0:bing-bang-a-bang,") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("16:bing-bang-a-bang") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("") &&
			do { print "not ok 4\n"; last CASE };
	netstring_verify("3:foo," , "4:foo,") &&
			do { print "not ok 4\n"; last CASE };
		
	print "ok 4\n";
}


#
# test 5; decode a valid netstring
# the result of 2 should decode as  bing-bang-a-bang
#
$string = netstring_decode($string);
if ($string eq "bing-bang-a-bang") {
	print "ok 5\n";
} else {
	print "not ok 5\n";
}


#
# test 6; decode another valid netstring
# 0:,  should decode to an empty string
#
$string = netstring_decode("0:,");
if ($string eq "") {
	print "ok 6\n";
} else {
	print "not ok 6\n";
}


#
# test 7; decode an invalid netstring
# decode of  bing-bang-a-bang  should fail
#
$string = netstring_decode("bing-bang-a-bang");
if (!$string) {
	print "ok 7\n";
} else {
	print "not ok 7\n";
}


#
# test 8; encode a list of strings
# "foo" "baz" should become "3:foo," "3:baz,"
#
@list = netstring_encode("foo", "baz");
if (scalar @list == 2 and $list[0] eq "3:foo," and $list[1] eq "3:baz,") {
	print "ok 8\n";
} else {
	print "not ok 8\n";
}

#
# test 9; decode a list of strings
# result of above should become "foo" "baz" again
#
@list = netstring_decode(@list);
if (scalar @list == 2 and $list[0] eq "foo" and $list[1] eq "baz") {
	print "ok 9\n";
} else {
	print "not ok 9\n";
}


#
# test 10; encode a list of strings in scalar context
# "foo" "baz" should become "3:foo,3:baz,"
#
$string = netstring_encode("foo", "baz");
if ($string eq "3:foo,3:baz,") {
	print "ok 10\n";
} else {
	print "not ok 10\n";
}


#
# test 11; encode a list reference of strings, in scalar context
# "foo" "baz" should become "3:foo,3:baz,"
#
$string = ["foo", "baz"];	#anonymous reference
$string = netstring_encode($string);
if ($string eq "3:foo,3:baz,") {
	print "ok 11\n";
} else {
	print "not ok 11\n";
}


#
# test 12; encode a list reference of strings, in list context
# "foo" "baz" should become "3:foo," "3:baz,"
#
$string = ["foo", "baz"];	#anonymous reference
@list = netstring_encode($string);
if (scalar @list == 2 and $list[0] eq "3:foo," and $list[1] eq "3:baz,") {
	print "ok 12\n";
} else {
	print "not ok 12\n";
}


#
# test 13; verify a list of valid strings in scalar context
#
@list = ("3:foo," , "3:baz,");
if (scalar(netstring_verify(@list))) {
	print "ok 13\n";
} else {
	print "not ok 13\n";
}


#
# test 14; verify a list of valid strings in list context
# The list above should be valid.
#
@list = netstring_verify(@list);
if (scalar @list == 2 and $list[0] and $list[1]) {
	print "ok 14\n";
} else {
	print "not ok 14\n";
}


#
# test 15; verify a list of with a mix of valid and invalid strings, 
# in list context
#
@list = netstring_verify("3:o," , "3:baz" , ":foa," , "5:whizz,");
if (scalar @list == 4 and !$list[0] and !$list[1] and !$list[2] and $list[3]) {
	print "ok 15\n";
} else {
	print "not ok 15\n";
}


#
# test 16; verify a list of with a mix of valid and invalid strings, 
# in scalar context
#
if (!scalar (netstring_verify("3:o," , "3:baz" , ":foa," , "5:whizz,"))) {
	print "ok 16\n";
} else {
	print "not ok 16\n";
}


#
# test 17; encode a string with newline into a netstring
# bing-bang\na-bang  should become  16:bing-bang\na-bang,
#
$string = netstring_encode("bing-bang\na-bang");
if ($string eq "16:bing-bang\na-bang,") {
	print "ok 17\n";
} else {
	print "not ok 17\n";
}


#
# test 18; verify a valid netstring
# the result of above should verify as a netstring
#
if (netstring_verify($string)) {
	print "ok 18\n";
} else {
	print "not ok 18\n";
}


#
# test 19; decode a valid netstring
# the result of 17 should decode as  bing-bang\na-bang
#
$string = netstring_decode($string);
if ($string eq "bing-bang\na-bang") {
	print "ok 19\n";
} else {
	print "not ok 19\n";
}
