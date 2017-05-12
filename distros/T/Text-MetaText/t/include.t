#
# include.t 
#
# MetaText test script
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'include'; $ntests = 3; 
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
my $mt = new Text::MetaText {
    LIB => 't/lib'
} || die "failed to create MetaText object\n";

# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    &test_file(++$loaded, $mt, $testname);
}

