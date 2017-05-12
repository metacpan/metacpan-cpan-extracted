#
# chomp.t 
#
# MetaText test script used to test behaviour of CHOMP parameter
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'chomp'; $ntests = 2; 
        $| = 1; print "1..", $ntests + 1, "\n"; }

END   { print "not ok 1\n" unless $loaded; }

use Text::MetaText;
use lib qw(. t);
use vars qw($ntests $stub $testname);

require "test.pl";

$loaded = 1;
print "ok 1\n";


# initialise test functions and set post processing callback
&init();


# create a MetaText object
my $mtchomp = Text::MetaText->new({
	CHOMP => 1
    }) || die "failed to create MetaText object\n";

my $mtnochomp = Text::MetaText->new({ 
	CHOMP => 0
    }) || die "failed to create MetaText object\n";

my @mt = ($mtchomp, $mtnochomp);

# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    &test_file(++$loaded, $mt[($loaded - 2) % 2], $testname);
}



