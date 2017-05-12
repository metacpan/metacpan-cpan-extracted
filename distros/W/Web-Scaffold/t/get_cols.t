# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Web::Scaffold;
*get_cols = \&Web::Scaffold::get_cols;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}
################################################################
################################################################

my $pagemenu = {
  one	=> {
	menu	=> [qw( one two four five)],
	submenu => [],
  },
  two	=> {},
  three	=> {
	submenu	=> [1,2,3],
  },
  four	=> {
	submenu => [1],
  },
  five	=> {
	submenu => [3,4],
  },
};

my $exp = 2;
my $got = get_cols($pagemenu,'one');
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;
