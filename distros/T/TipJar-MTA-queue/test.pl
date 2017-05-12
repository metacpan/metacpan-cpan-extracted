# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
# use TipJar::MTA::queue;
-d '/tmp/MTA_test_dir' or die <<EOF;

MUST CREATE /tmp/MTA_test_dir DIRECTORY
for instance by installing TipJar::MTA

EOF

use TipJar::MTA::queue '/tmp/MTA_test_dir'; # what TipJar::MTA test.pl uses
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


ok(my $m = new TipJar::MTA::queue);

# from perldoc -f gmtime
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)
	=  gmtime(time);
#adjust date for printability:
$year += 1900;
$wday = [qw/Sun Mon Tue Wed Thu Fri Sat/]->[$wday];
$mon = [qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/]->[$mon];
# zero-pad time-of-day components
$hour = substr("0$hour", -2);
$min = substr("0$min", -2);
$sec = substr("0$sec", -2);

ok($m->return_address('<>'));
ok($m->recipient([[['davidnico@cpan.org'],
'mta_queue_test_recipient@davidnicol.com']]));

# example date format is: Tue, 22 Apr 2003 22:29:14 -0400
ok($m->data(<<EOF ));
Date: $wday, $mday $mon $year $hour:$min:$sec +0000
X-This-Is: the message sent from the TipJar::MTA::queue test script
To: "TipJar::MTA::queue author" <davidnico\@cpan.org>
From: "MTA Q. Module Tester" <$ENV{USER}\@$ENV{HOSTNAME}>
Subject: TipJar::MTA::queue test success

  $ENV{USER}\@$ENV{HOSTNAME}
has succeeded in installing TipJar::MTA::queue,
or at least in running the test script.

OSTYPE: $ENV{OSTYPE}

EOF


ok($m->enqueue());


