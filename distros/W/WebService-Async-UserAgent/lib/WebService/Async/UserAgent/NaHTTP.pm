package WebService::Async::UserAgent::NaHTTP;
$WebService::Async::UserAgent::NaHTTP::VERSION = '0.006';
use strict;
use warnings;

use parent qw(WebService::Async::UserAgent);

=head1 NAME

WebService::Async::UserAgent::NaHTTP - make requests using L<Net::Async::HTTP>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Provides a L</request> method which will use L<Net::Async::HTTP> to make
requests and return a L<Future> containing the result. Used internally by
L<WebService::Async::UserAgent>.

=cut

use Future;
use Net::Async::HTTP;
use HTTP::Cookies;

=head2 request

Issues the request. Expects a single L<HTTP::Request> object,
and returns a L<Future> which will resolve to the decoded
response content on success, or the failure reason on failure.

=cut

sub request {
	my ($self, $req, %args) = @_;
	my $host = delete $args{host};
	my $port = delete $args{port};
	unless(defined($host) && defined($port)) {
		my ($h, $p) = split /:/, '' . $req->uri->host_port;
		$host //= $h;
		$port //= $p;
	}
	my $ssl = delete($args{ssl}) // ($req->uri->scheme eq 'https');
	$self->ua->do_request(
		request => $req,
		host    => $host,
		port    => $port || ($ssl ? 443 : 80),
		SSL     => ($ssl ? 1 : 0),
		%args,
	)->transform(
		done => sub {
			shift->decoded_content
		},
	);
}

=head2 ua

Returns a L<Net::Async::HTTP> instance.

=cut

sub ua {
	my $self = shift;
	unless($self->{ua}) {
		my $ua = Net::Async::HTTP->new(
			user_agent               => $self->user_agent,
			max_connections_per_host => ($self->parallel // 1),
			pipeline                 => 0,
			fail_on_error            => 1,
			timeout                  => $self->timeout,
			cookie_jar               => ($self->{jar} ||= HTTP::Cookies->new),
			decode_content           => 1,
			$self->ssl_args,
		);
		$self->loop->add($ua);
		$self->{ua} = $ua;
	}
	$self->{ua};
}

sub loop { shift->{loop} }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
