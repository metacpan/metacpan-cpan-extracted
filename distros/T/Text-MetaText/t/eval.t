#
# eval.t 
#
# MetaText test script
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'eval'; $ntests = 2; 
        $| = 1; print "1..", $ntests + 1, "\n"; }

END   { print "not ok 1\n" unless $loaded; }

use Text::MetaText;
use lib qw(. t);
use vars qw($ntests $stub $testname);

require "test.pl";

$loaded = 1;
print "ok 1\n";


&init();


# create a MetaText object
my $mt = new Text::MetaText || die "failed to create MetaText object\n";

# pre-defined variables
my $predefs = {
    'foo'  => "predef-foo",
    'fooz' => "predef-fooz",
    'bar' => "predef-bar",
};

# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    &test_file(++$loaded, $mt, $testname, $predefs);
}

