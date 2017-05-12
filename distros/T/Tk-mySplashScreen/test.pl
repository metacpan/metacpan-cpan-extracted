# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
use Tk::mySplashScreen;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

##test create (2)
print "testing create ...\n";
$splash = mySplashScreen->new();
ok(Tk::Exists($splash), 1, "MainWindow creation failed");

##testing new message (3)
print "testing messages ...\n";
sleep(1);
$splash->configure(-text => "new message!");
$splash->update();
sleep(1);
$splash->configure(-text => "annother new message!");
$splash->update();
sleep(1);
ok(1);

##testing new image (4)
print "testing image ...\n";
$splash->configure(-image => "./trog_splash.gif");
sleep(1);
$splash->configure(-text => "BURNINRATING!!!! ....");
$splash->update();
sleep(1);
ok(1);

##hide/unhide (5)
print "testing hide ...\n";
$splash->configure(-text => "testing hide!");
$splash->update();
$splash->configure(-hide => 1);
$splash->update();
sleep(1);
print "testing unhide ...\n";
$splash->configure(-hide => 0);
$splash->update();
ok(1);

##alternate content (6)
print "testing alternate content ...\n";
$splash->configure(-text => "testing alternate content ...");
$splash->update();
my $frame = $splash->AltContent();
$frame->Label(-text => "enter your password")->pack();
$frame->Entry()->pack();
$splash->update();
sleep(1);
$splash->configure(-text => "looks good!");
$frame->destroy();
$splash->update();
sleep(1);
ok(1);

1;