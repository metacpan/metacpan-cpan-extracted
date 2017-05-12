# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::QL;
$loaded = 1;
print "ok 1\n";
my $testnum = 2;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$output = XML::QL->query(<<'EOQUERY');
WHERE
	<child name="$child"/>
IN
	"perl.com.xml"
CONSTRUCT
	Child: $child
EOQUERY

$output ? print "ok ", $testnum++, "\n" : print "not ok ", $testnum++, "\n";

my $compare = 'Child: Grant\'s CGI Framework
Child: The Common Gateway Interface
Child: Welcome to The Perl Institute
Child: perlWWW
Child: libwww-perl: WWW Protocol Library for Perl
Child: Tom Christiansen\'s Mox.Perl.COM Home Page
Child: CGI Programming Class
Child: Ada 95 Binding to CGI
Child: The Common Gateway Interface
Child: Jarkko Hietaniemi
';

$output eq $compare ? print "ok ", $testnum++, "\n" : print "not ok ", $testnum++, "\n", "::\n$output\n";
