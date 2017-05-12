#
# declare.t 
#
# MetaText test script for testing blocks pre-declared with the declare()
# method
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'declare'; $ntests = 1; 
        $| = 1; print "1..", $ntests + 1, "\n"; }

END   { print "not ok 1\n" unless $loaded; }

use Text::MetaText;
use lib qw(. t);
use vars qw($ntests $stub $testname);

require "test.pl";

$loaded = 1;
print "ok 1\n";


&init();

my $text = "%% greeting %%\nthis is pre-declared text\n%% farewell %%";
my $tags = { 'greeting' => 'Welcome', 'farewell' => 'Adieu' };
my $decl = 'declared_block';
my $comp = 'compiled_block';

# create a MetaText object
my $mt = new Text::MetaText { 
#	'debuglevel'    => 'function',
	'lib'      => "t/lib",
    } || die "failed to create MetaText object\n";

# pre-declare a simple text object
$mt->declare($text, $decl);

# now for a more complex text/directive array ref
$mt->declare(make_block(), $comp);

# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    &test_file(++$loaded, $mt, $testname, $tags);
}




sub make_block {

    # create a directive factory
    my $factory  = Text::MetaText::Factory->new() 
	|| die "Factory construction failed: ",
           Text::MetaText::Factory::error(), "\n";

    # there are better ways to construct directives, but this is a quick
    # hack that gets the job done (albeit slowly)
    my $t1 = "INCLUDE $decl greeting=\"Hey, dude!\" farewell=\"see ya\"";
    my $md = $factory->create_directive($t1);

    # construct a handy error string if directive build failed
    $md = "failed to make directive: " . $factory->error()
       	unless defined $md;

    return [ 
	"some pre-directive text",
	"\n", 
	$md, 
	"\n",
	"some post-directive text" 
    ];
}

