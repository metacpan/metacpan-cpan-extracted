#
# exec.t 
#
# MetaText test script
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'exec'; $ntests = 2; 
        $| = 1; print "1..", $ntests + 1, "\n"; }

END   { print "not ok 1\n" unless $loaded; }

use Text::MetaText;
use lib qw(. t);
use vars qw($ntests $stub $testname);

require "test.pl";

$loaded = 1;
print "ok 1\n";


&init();


#
# create a derived class
#

package MyMetaText;
use vars qw( @ISA );
@ISA = qw(Text::MetaText);

sub mt_method {
    my $self     = shift;
    my $params   = shift;
    my $paramstr = shift;
    my $text     = "mt_method($paramstr)\n";

    foreach (keys %$params) {
	$text .= sprintf("    %-20s => %s\n", $_, $params->{ $_ });
    }
    chomp $text;
    $text;
}


package main;


# create a MetaText object
my $mt = new MyMetaText { 
	EXECUTE    => 2,
    } || die "failed to create MetaText object\n";

my $predefs = {
    'bar' => 'This is the bar'
};

# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    &test_file(++$loaded, $mt, $testname, $predefs);
}


sub mt_function {
    my $params   = shift;
    my $paramstr = shift;
    my $text     = "mt_function($paramstr)\n";

    foreach (keys %$params) {
	$text .= sprintf("    %-20s => %s\n", $_, $params->{ $_ });
    }
    chomp $text;
    $text;
}
