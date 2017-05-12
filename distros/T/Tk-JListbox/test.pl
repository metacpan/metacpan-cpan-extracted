# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..last_test_to_print\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use JListbox;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

require Tk::DialogBox;

$mw = MainWindow->new;

$jlb = $mw->JListbox(-justify=>'center', -width=>75, -popupmenu=>1);

$jlb->pack(-expand=>1, -fill=>'x');

$jlb->insert('end',"Hello World!");
$jlb->insert('end',"How are you");
$jlb->insert('end',"ABCDEFG");
$jlb->insert('end',"12345");

$cButton = $mw->Button(-text=>"Center Text", -command=>sub{
   $jlb->configure(-justify=>'center')}
);

$rButton = $mw->Button(-text=>"Right Justify Text", -command=>sub{
   $jlb->configure(-justify=>'right')}
);

$eButton = $mw->Button(-text=>"Exit", -command=>sub{exit});

$cButton->pack;
$rButton->pack;
$eButton->pack;

MainLoop;





