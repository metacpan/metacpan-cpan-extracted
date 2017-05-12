# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-StatusBar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Tk::StatusBar') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

use Tk;
use Tk::StatusBar;

my $mw = new MainWindow;
$mw->Button->pack;
my $sb = $mw->StatusBar;
my $l  = $sb->addLabel;
my $p  = $sb->addProgressBar;

ok($sb->class eq 'StatusBar', 'verify statusbar creation');
ok($l->class eq 'Label', 'verify embedded label creation');
ok($p->class eq 'ProgressBar', 'verify embedded progressbar creation');
ok($sb->parent eq $mw, "verify statusbar's parent");
ok($l->parent eq $sb, "verify label's parent");
ok($p->parent eq $sb, "verify progressbar's parent");
ok($p->cget(-width) == 17, "verify progressbar's width");
ok(($mw->packSlaves)[0]->class eq 'StatusBar', "verify packing order");