#!perl -w
use Test;
BEGIN { plan tests => 4 }

use WWW::Yahoo::InboundLinks; 

# please register your own yahoo app id when using this code in your application
my $ylinks = WWW::Yahoo::InboundLinks->new ('kx3hFsLV34HOcYXmoaxIcWaD6CLVSVT2jOHKcnEnnjrOk3pB0b33I7uW0.OlBp8ksEk-');

ok $ylinks;

$ylinks->user_agent->timeout (10);

foreach (qw(yahoo.com google.com yandex.ru)) {
	my ($count, $resp, $struct) = $ylinks->get ("http://$_");
	
	if (! $resp->is_success) {
		warn "no internet connection?\n";
		ok (1); # not ok at all, but this is yahoo and internet connections problem
	} elsif (!defined $struct && $resp->content =~ /Rate Limit Exceeded/si) {
		warn "limit exceeded\n";
		ok (1); # because limit exceeded, but response ok
	} elsif (defined $struct and exists $struct->{ResultSet}->{totalResultsAvailable}) {
		warn "\n$_: $struct->{ResultSet}->{totalResultsAvailable} results available\n";
		ok (1); # response ok and field ok, but field value may be 0
	} else {
		# unknown reason. send details
		warn "result unknown. request uri:\n"
			. $resp->request->uri
			. "\nresponse content:\n"
			. $resp->content . "\n";

		ok (0);
	}
	
}


exit;

__END__
