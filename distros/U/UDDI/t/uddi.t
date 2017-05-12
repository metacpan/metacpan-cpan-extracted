#!./perl

use URI;
my $test_registry = URI->new("http://uddi.microsoft.com/inquire");

# check that we have a network connection
use IO::Socket;
unless (IO::Socket::INET->new(PeerAddr => $test_registry->host,
			      PeerPort => $test_registry->port,
			      Timeout  => 20,
			      Proto    => 'tcp',
			     ))
{
    print "1..0\n";
    print $@, "\n";
    exit;
}

print "1..5\n";

# things ought to work now
use UDDI;
$UDDI::registry = $test_registry;

my $b = UDDI::find_business(name => "m");
for ($b->businessInfos->businessInfo) {
    print $_->name, "\n";
    if ($_->name->as_string eq "Microsoft Corporation") {
	# XXX should probably have some more well known data to test
	# against.  Can probably wait until the real service goes live.
	print "ok 1\n";
	my $key = $_->businessKey;
	print "$key\n";
	my $d = UDDI::get_businessDetail($key);
	#print "$d\n";
	my $e = $d->businessEntity;
	print "ok 2\n" if $e;
	my @services = $e->businessServices->businessService;
	print "ok 3\n" if @services > 2;
	for ($e->businessServices->businessService) {
	    print "  ", $_->name, "\n";
	}
    }
}

# Test failure
print "not " if UDDI::get_businessDetail("xyzzy");
print "ok 4\n";

print "not " unless $UDDI::err{type} eq "SOAP" &&
                    $UDDI::err{code} eq "E_fatalError";
print "ok 5\n";

#use Data::Dump; Data::Dump::dump(\%UDDI::err);
