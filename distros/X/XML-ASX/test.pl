# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::ASX;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $asx = XML::ASX->new;
print "ok 2\n";
$asx->add_param('KEY3'=>'VAL3');

my $entry = $asx->add_entry;
$entry->banner("http://some.where/some.png");
$entry->moreinfo("http://127.0.0.1/");
$entry->abstract("Localhost");
print "ok 3\n";

$asx->abstract("Allen's ASX Playlist");
$asx->title("Streaming Multimedia to a Computer Near You!");
$asx->author("Allen Day <allenday\@ucla.edu>");
$asx->base("http://www.ucla.edu/");
$asx->copyright("(c) 2002, Allen Day");
$asx->target("http://sumo.genetics.ucla.edu/~allenday/");
$asx->moreinfo("More About Allen");
$asx->logo_icon("http://some.where/some.gif");
$asx->logo_mark("http://some.where/some.jpg");
$asx->banner("http://some.where/some.bmp");
print "ok 4\n";

my $event = $asx->add_event;
$event->name("The Big Bang");
$event->whendone("RESUME");
print "ok 5\n";

my $repeat = $asx->add_repeat;
$repeat->count(10);
$repeat->add_entry($entry);
my $entry2 = $repeat->add_entry;
$entry2->clientskip("NO");
print "ok 6\n";

$entry->add_ref('http://www.1-up.net/bogus.asf');
$entry->add_ref('http://www.wooly.org/not.an.mpeg');
$entry->add_param('KEY1'=>'VAL1');
$entry->add_param('KEY2'=>'VAL2');
print "ok 7\n";

$asx;
print "ok 8\n";

