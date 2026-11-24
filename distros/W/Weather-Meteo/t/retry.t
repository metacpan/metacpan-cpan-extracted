#!perl -wT

use strict;
use warnings;

use Test::Most;
use HTTP::Response;

BEGIN { use_ok('Weather::Meteo') }

my $body = '{"hourly":{"rain":[0]},"daily":{}}';
my %args = (latitude => 51.34, longitude => 1.42, date => '2022-12-25');

# A UA that returns the given status codes in order, then 200
{
	package Seq::UA;
	sub new { my ($c, @codes) = @_; return bless { codes => [@codes], calls => 0 }, $c }
	sub get {
		my $self = shift;
		$self->{calls}++;
		my $code = shift(@{$self->{codes}}) // 200;
		my $r = HTTP::Response->new($code, 'x');
		$r->content($body) if $code == 200;
		return $r;
	}
}

sub meteo {
	my ($ua, %extra) = @_;
	return Weather::Meteo->new(
		ua => $ua, retry_delay => 0,
		cache => CHI->new(driver => 'Memory', datastore => {}),
		%extra,
	);
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

foreach my $code (429, 502, 503, 504) {
	my $ua = Seq::UA->new($code, $code);
	ok(defined(meteo($ua)->weather(%args)), "HTTP $code is retried and then succeeds");
	is($ua->{calls}, 3, "HTTP $code: 3 calls made");
}

{
	my $ua = Seq::UA->new(500);
	ok(!defined(meteo($ua)->weather(%args)), 'HTTP 500 is not retried');
	is($ua->{calls}, 1, '500: one call only');

	$ua = Seq::UA->new(404);
	ok(!defined(meteo($ua)->weather(%args)), 'HTTP 404 is not retried');
	is($ua->{calls}, 1, '404: one call only');
}

{
	my $ua = Seq::UA->new((503) x 10);
	ok(!defined(meteo($ua)->weather(%args)), 'persistent 503 gives up');
	is($ua->{calls}, 4, 'default: 1 call + 3 retries');

	$ua = Seq::UA->new((503) x 10);
	ok(!defined(meteo($ua, max_retries => 0)->weather(%args)), 'max_retries 0 disables retry');
	is($ua->{calls}, 1, 'max_retries 0: one call');

	$ua = Seq::UA->new((503) x 10);
	meteo($ua, max_retries => 1)->weather(%args);
	is($ua->{calls}, 2, 'max_retries 1: two calls');
}

{
	# Retry-After is honoured (1s), and a numeric delay is used for backoff
	my $ua = Seq::UA->new(429);
	no warnings 'redefine';
	local *Seq::UA::get = sub {
		my $self = shift;
		$self->{calls}++;
		if($self->{calls} == 1) {
			my $r = HTTP::Response->new(429, 'x');
			$r->header('Retry-After' => 1);
			return $r;
		}
		my $r = HTTP::Response->new(200, 'x');
		$r->content($body);
		return $r;
	};
	my $t = time();
	ok(defined(meteo($ua)->weather(%args)), 'succeeds after Retry-After');
	cmp_ok(time() - $t, '>=', 1 - 0.01, 'Retry-After wait observed');
}

throws_ok { Weather::Meteo->new(max_retries => 'x') } qr/Invalid max_retries/, 'bad max_retries croaks';
throws_ok { Weather::Meteo->new(retry_delay => '-1') } qr/Invalid retry_delay/, 'bad retry_delay croaks';

done_testing();
