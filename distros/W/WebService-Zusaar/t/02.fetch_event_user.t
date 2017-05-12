# Fetch event/user test (Offline mock)
use Test::More;
use strict;
use warnings;
use utf8;

use WebService::Zusaar;

use DateTime::Format::ISO8601;
use File::Slurp qw//;
use FindBin;
use Plack::Loader;
use Test::TCP;
use Data::Dumper;

# Prepare the Test API response
my $test_api = sub {
	my $content = File::Slurp::read_file("$FindBin::Bin/data/sample_event_user.json");
	[ 200, [ 'Content-Type' => 'application/json' ], [ $content ] ];
};

# Prepare the Expected patterns (It's same as a part of item values of Test API response)
my @expect_patterns = (
	[
		{
			profile_url => 'http//example.com/aaa',
			user_id => '123'
		},
		{
			profile_url => 'http//example.com/bbb',
			user_id => '456'
		},
		{
			profile_url => 'http//example.com/ccc',
			user_id => '789'
		},
	],
);

my $expect_patterns_i = 0;

# Prepare a Test client
my $client = sub {
	my $baseurl = shift;

	# Initialize a instance
	my $obj = WebService::Zusaar->new(encoding => 'utf8', baseurl => $baseurl);
	
	# Fetch event/user
	$obj->fetch('event/user', event_id => '999999');

	# Iterate a fetched events
	while(my $event = $obj->next) {
		foreach my $user(@{$event->users}){
			# Compare values of item, with Expected pattern
			my $ptn = $expect_patterns[0]->[$expect_patterns_i];
			foreach(keys %$ptn){
				is($user->$_, $ptn->{$_}, "Item > $_");
			}
			$expect_patterns_i += 1;
		}
	}
};

# Test a module
test_tcp(
	client => sub {
		# Test client
		my $port = shift; # Test API server port
		my $baseurl = "http://127.0.0.1:$port/";
		# Initialize module, and fetch (with specified baseurl by Test API server)
		$client->($baseurl);
	},
	server => sub {
		# Test API server (It serves a Test API response)
		my $port = shift;
		my $server = Plack::Loader->auto(port => $port, host => '127.0.0.1',);
		$server->run($test_api);
	},
);

# End
done_testing;