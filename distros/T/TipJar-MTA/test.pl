# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use TipJar::MTA ;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$Tipjar::MTA::LogToStdout = 1;

use Sys::Hostname;
print "testing hostname function\n";
my $HN = hostname();
# print "[$HN,$TipJar::MTA::MyDomain]\n";
ok($HN,$TipJar::MTA::MyDomain);

print "testing dnsmx function\n";
my @cpan = TipJar::MTA::dnsmx( 'yahoo.com' );
print "yahoo.com MX: @cpan\n";
ok(@cpan > 1); # this had been failing since cpan.org switched to only one mx

print "$$ using /tmp/MTA_test_dir for basedir in test script\n";
$TipJar::MTA::basedir = '/tmp/MTA_test_dir';

$SIG{CHLD} = sub{ print "$$ child signal\n"; };
$TipJar::MTA::OnlyOnce = 'testing in module test script';
TipJar::MTA::run();

print "Waiting for MTA run to complete\n";
ok( wait, $TipJar::MTA::LastChild );




