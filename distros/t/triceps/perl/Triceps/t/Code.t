#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for streaming functions: FnReturn, FnBinding etc.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 26 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $res;
my $codeClosure = sub { return "testClosure"; };
my $codeString = 'return "testString";';

$res = Triceps::Code::compile(undef);
ok(!defined $res);

$res = Triceps::Code::compile($codeClosure);
ok($res, $codeClosure);
ok(&$res(), "testClosure");

$res = Triceps::Code::compile($codeString);
ok(ref $res, "CODE");
ok(&$res(), "testString");

# an integer gets converted to a string which ends up as a function returning
# that integer
$res = Triceps::Code::compile(1);
ok(ref $res, "CODE");
ok(&$res(), 1);

$res = eval { Triceps::Code::compile("1 ) 2"); };
ok(!defined $res);
#print $@;
ok($@, qr/^Code snippet: failed to compile the source code
Compilation error: syntax error at .*
The source code was:
     1 sub {
     2 1 \) 2
     3 }
 at .*\/Code.pm line \d*\.?
\tTriceps::Code::compile\('1 \) 2'\) called at .*\/Code.t line \d*\.?
\teval {...} called at .*\/Code.t line \d*\.?
/);

$res = eval { Triceps::Code::compile("1 ) 2", "test code"); };
ok(!defined $res);
#print $@;
ok($@, qr/^test code: failed to compile the source code
Compilation error: syntax error at .*
The source code was:
     1 sub {
     2 1 \) 2
     3 }
 at .*\/Code.pm line \d*\.?
\tTriceps::Code::compile\('1 \) 2', 'test code'\) called at .*\/Code.t line \d*\.?
\teval {...} called at .*\/Code.t line \d*\.?
/);

# a completely wrong value
$res = eval { Triceps::Code::compile([1, 2]); };
ok(!defined $res);
ok("$@", qr/^Code snippet: code must be a source code string or a reference to Perl function at/);

# a completely wrong value, with custom name
$res = eval { Triceps::Code::compile([1, 2], "test code"); };
ok(!defined $res);
ok("$@", qr/^test code: code must be a source code string or a reference to Perl function at/);

#########################
# Code formatting

# the lines 4-($-2) get ignored when counting the indentation,
# the lines with no indentation get ignored too;
# lines in the middle with indentation less that the detected one
# have their indentation left as-is
$res = Triceps::Code::alignsrc("one
\  two
\   three
\ four
\  five
six");
#print "$res\n";
ok($res, "one
two
 three
 four
five
six");
ok($Triceps::Code::align_removed_lines, 0);

# the old indentation gets substituted; new indentation added to all lines
$res = Triceps::Code::alignsrc("  one
\   two
\    three
\   four
five", "++");
#print "$res\n";
ok($res, "++one
++ two
++  three
++ four
++five");

# the tabs are preferred to spaces when detecting
# indentation (and then the spaces stay unchanged)
$res = Triceps::Code::alignsrc("one
\  two
\   three
\t\t\tfour
\t\tfive
\tsix", "++", "--");
#print "$res\n";
ok($res, "++one
++  two
++   three
++----four
++--five
++six");

# the default replacement for a tab is two spaces;
# and the removal of the last \n and empty lines at the front
$res = Triceps::Code::alignsrc("  " . "


one
\  two
\   three
\t\t\tfour
\t\tfive
\tsix
", "++", "");
#print "$res\n";
ok($res, "++one
++  two
++   three
++    four
++  five
++six");
ok($Triceps::Code::align_removed_lines, 3);

# with line numbers
$res = Triceps::Code::numalign("one
\  two
\   three
\t\t\tfour
\t\tfive
\tsix", "++", "--");
#print "$res\n";
ok($res, "++   1 one
++   2   two
++   3    three
++   4 ----four
++   5 --five
++   6 six");
ok($Triceps::Code::align_removed_lines, 0);

# with line numbers and removed lines
$res = Triceps::Code::numalign("


one
\  two
\   three
\t\t\tfour
\t\tfive
\tsix", "++", "--");
#print "$res\n";
ok($res, "++   4 one
++   5   two
++   6    three
++   7 ----four
++   8 --five
++   9 six");
ok($Triceps::Code::align_removed_lines, 3);

