# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Win32::Net::Session;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my $server = $ARGV[0] || $ENV{COMPUTERNAME};
my $level = $ARGV[1] || 3;
print "using Server: $server and Level: $level.. \n";
my $SESS= Win32::Net::Session->new($server, $level);
my $ret = $SESS->GetSessionInfo();
my $numsessions = $SESS->NumberofSessions();
if($numsessions == 0) {print "No Clients connected\n"; exit; }
print "Number of Sessions: " . $numsessions . "\n";
my %hash = %$ret;

my $key;
my $count=0;

while($count < $numsessions)
{
	my %h = %{$hash{$count}};
	print "The key: $count\n";
	foreach $key (keys %h)
	{
		print "$key=" . $h{$key} . "\n";
	}
	print "\n";
	$count++;
}
