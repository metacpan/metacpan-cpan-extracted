$| = 1;
use strict;
use warnings;

use EV;
use Net::Curl::Multi;
use Net::Curl::Easy qw(/^CURLOPT_/);
use Net::Curl::Multi::EV;

my $multi = Net::Curl::Multi->new();
my $curl_ev = Net::Curl::Multi::EV::curl_ev($multi);

my @urls = (
	"http://www.bing.com/",
	"http://www.bing.com/search?q=curl",
	"http://www.bing.com/search?q=perl+curl",
);


my $n = @urls;
sub add_request {
	my $url = shift @urls or return;
	print "starting to fetch $url\n";

	my $easy = Net::Curl::Easy->new();

	$easy->setopt(CURLOPT_URL, $url);
	$easy->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$easy->setopt(CURLOPT_WRITEHEADER, \ my $headers);
	$easy->setopt(CURLOPT_FILE,        \ my $body);


	my $finish = sub {
		my ($easy, $result) = @_;
		$n--;

		if ($headers) {
			my @headers = split /\r?\n\r?\n/, $headers;
			my $last_headers = $headers[-1];
			my @last_headers = split /\r?\n/, $last_headers;;

			my $first_line = shift @last_headers;
			my ($code, $message) = $first_line =~ m/HTTP\/\d\.\d\s+(\d+)\s+(.+)/;
			my $body_length = length $body;

			print "$code ($message)\t$url\t$body_length\n";
		} else {
			print "result: $result (", 0 + $result ,") for $url\n";
		}

		if (@urls) {
			add_request();
		} else {
			EV::break() unless $n;
		}
	};

	$curl_ev->($easy, $finish, 4 * 60);

	return 1;
}


foreach (1 .. 10) {
	add_request() or last;
}


EV::run();
