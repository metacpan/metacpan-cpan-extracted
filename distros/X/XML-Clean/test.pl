# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Clean;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $result = XML::Clean::clean("<foo bar>foo");
print ($result eq "<foo>foo</foo>" ? "ok 2\n" : "not ok 2\n");

$result = XML::Clean::clean ("<foo bar>barfoo",1.5);
print ($result eq "<?xml version=\"1.5\" encoding=\"ISO-8859-1\"?>\n<foo>barfoo</foo>" ? "ok 3\n" : "not ok 3\n");

$result = XML::Clean::clean ("bar <foo bar=10> bar",1.6,{root=>"XML_ROOT",encoding=>"ISO-8859-2"} );
print ($result eq '<?xml version="1.6" encoding="ISO-8859-2"?>
<XML_ROOT>
bar <foo bar="10"> bar</foo></XML_ROOT>' ? "ok 4\n" : "not ok 4" );

