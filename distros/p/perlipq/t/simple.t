#
# $Id: simple.t,v 1.4 2001/10/22 13:47:16 jmorris Exp $
#
# Simple test.
#
package simple_t;
use strict;
$^W = 1;

my $tests = 4;

sub test
{
	my ($q, $procfile, $procpid);
	
	print "1..$tests\n";

	#
	# Test 1 - Load module(s)
	#
	use IPTables::IPv4::IPQueue qw(:constants);
	
	print "ok 1\n";

	#
	# Test 2 - IPQueue object creation
	#
	$q = new IPTables::IPv4::IPQueue(copy_mode => &IPQ_COPY_PACKET,
	                                 copy_range => 1500);

	if (!defined $q) {
		print "not ok 2\n";
		die "Fatal: " . IPTables::IPv4::IPQueue->errstr;
	} else {
		print "ok 2\n";
	}

	#
	# Test 3 -  Verify against /proc entry
	#
	$procfile = '/proc/net/ip_queue';
	
	if (!open PROC, "<$procfile") {
		print "not ok 3\n";
		die "Fatal: unable to open $procfile: $!";
	}
	
	while (<PROC>) {
		if (/^Peer pid\s+:\s+(\d+)/) {
			$procpid = $1;
			last;
		}
	}
	close PROC;
	
	if (!$procpid) {
		print "not ok 3\n";
	} else {
		if ($procpid != $$) {
			print "not ok 3\n";
		} else {
			print "ok 3\n";
		}
	}
	
	#
	# Test 4 - test get_message() with 20 millisecond
	# timeout, assumes no packet will arrive, may not return
	# on failure.
	#
	my $packet = $q->get_message(1000 * 2);
	if (defined $packet) {
		print "not ok 4\n";
	} else {
		if (IPTables::IPv4::IPQueue->errstr eq 'Timeout') {
			print "ok 4\n";
		} else {
			print "not ok 4\n";
		}
	}
	
}

test();

