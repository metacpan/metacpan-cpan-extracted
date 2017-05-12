package WebService::Bitcoin::BTCe;
# ABSTRACT: API support for the BTC-e.com Bitcoin exchange
use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

WebService::Bitcoin::BTCe - interact with the btc-e.com bitcoin exchange

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

Please read the btc-e.com documentation first. Pay careful attention to security-related
things such as 2FA. Read the code for this module before trusting your account details to
it.

=cut

use Future;
use Future::Utils qw(try_repeat);
use HTTP::Request;
use JSON::MaybeXS;
use Digest::SHA qw(hmac_sha512_hex sha256_hex);
use List::Util qw(pairmap);
use List::UtilsBy qw(nsort_by);
use Variable::Disposition qw(retain_future);
use Log::Any qw($log);

=head1 METHODS

=cut

=head2 new

Pass these for the trading API (not needed for L</depth>):

=over 4

=item * key - your BTC-e.com API key

=item * secret - your BTC-e.com API secret 

=back

The privileges for the key/secret combination will determine which methods
succeed or fail.

If you're using this with L<IO::Async>:

 my $btce = WebService::Bitcoin::BTCe->new(
  key => '...',
  secret => '...',
  timed => sub { $loop->delay_future(@_) },
  ua => WebService::Async::UserAgent->new(loop => $loop),
 );

If you're using it with something else, you'll need an alternative for the
L</timed> callback, and a user agent which conforms to the
L<WebService::Async::UserAgent> API.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub timed {
	my ($self, %args) = @_;
	return Future->fail('no timer support') unless $self->{timed};
	$self->{timed}->(%args)
}

=head2 depth

Returns the current trading pairs for the given currencies.

Resolves to a hashref containing:

=over 4

=item * lowest_ask

=item * highest_ask

=item * asks

=item * bids

=back

Values returned will be cached for 2 seconds. If you don't provide a way
to run code after a timeout, they will be cached indefinitely.

=cut

sub depth {
	my ($self, %args) = @_;
	my $pair = delete($args{pair}) || 'btc_usd';
	return $self->{depth}{$pair} ||= do {
		retain_future(
			$self->timed(
				after => 2
			)->then(sub {
				delete $self->{depth}{$pair};
			})
		);
		$self->ua->get(
			$self->base_url . '/api/3/depth/' . $pair
		)->then(sub {
			eval {
				my $data = $self->json->decode(shift);
				my ($lowest_ask) = nsort_by { $_->[0] } @{$data->{btc_usd}{asks}};
				my ($highest_bid) = reverse nsort_by { $_->[0] } @{$data->{btc_usd}{bids}};
				Future->done({
					lowest_ask => $lowest_ask->[0],
					highest_bid => $highest_bid->[0],
					asks => $data->{$pair}{asks},
					bids => $data->{$pair}{bids},
				})
			} or Future->fail($@, 'btc-e', 'exception while decoding')
		})
	}
}

=head2 account_balance

Resolves to a hashref containing balances for all currencies.

=cut

sub account_balance {
	my ($self, %args) = @_;

	$self->info(%args)->transform(
		done => sub { shift->{funds} }
	)
}

=head2 info

Returns all information about this account and key/secret access.

=over 4

=item * funds - hashref of currency => amount for account balances

=item * rights - hashref listing all access rights this API key has

=item * transaction_count - number of transactions executed

=item * open_orders - total number of open (unexecuted/partially filled) orders

=item * server_time - current server time, used for latency calculation

=back

Rights are currently:

=over 4

=item * info

=item * trade

=item * withdraw

=back

=cut

sub info {
	my ($self, %args) = @_;

	$self->error_check(sub {
		my $req = $self->build_request(
			method => 'getInfo',
		);
		$self->ua->request(
			$req,
			host    => $self->host,
			port => $self->port,
			ssl     => $self->ssl,
		)->then(sub {
			eval {
				my $body = shift;
				my $data = $self->json->decode($body);
				return Future->done($data->{return}) if $data->{success};
				return Future->fail($data->{error}, 'btc-e');
			} or return Future->fail($@, 'exception'); 
		})
	})
}

=head2 active_orders

Returns all active orders for the current account.

=cut

sub active_orders {
	my ($self, %args) = @_;

	$self->error_check(sub {
		my $req = $self->build_request(
			method => 'ActiveOrders',
		);
		$self->ua->request(
			$req,
			host    => $self->host,
			port => $self->port,
			ssl     => $self->ssl,
		)->then(sub {
			eval {
				my $body = shift;
				my $data = $self->json->decode($body);
				return Future->done($data->{return}) if $data->{success};
				return Future->done({ }) if $data->{error} eq 'no orders';

				return Future->fail($data->{error}, 'btc-e')
			} or return Future->fail($@, 'exception');
		})
	})
}

=head2 order_info

Returns info for a given order.

=cut

sub order_info {
	my ($self, $id, %args) = @_;

	$self->error_check(sub {
		my $req = $self->build_request(
			method => 'OrderInfo',
			order_id => $id,
		);
		$self->ua->request(
			$req,
			host    => $self->host,
			port => $self->port,
			ssl     => $self->ssl,
		)->then(sub {
			eval {
				my $body = shift;
				my $data = $self->json->decode($body);
				return Future->done($data->{return}{$id}) if $data->{success};
				return Future->done({ }) if $data->{error} eq 'not found';

				return Future->fail($data->{error}, 'btc-e')
			} or return Future->fail($@, 'exception');
		})
	})
}

=head2 cancel_order

Cancels the given order.

=cut

sub cancel_order {
	my ($self, $id, %args) = @_;

	$self->error_check(sub {
		my $req = $self->build_request(
			method => 'CancelOrder',
			order_id => $id,
		);
		$self->ua->request(
			$req,
			host    => $self->host,
			port => $self->port,
			ssl     => $self->ssl,
		)->then(sub {
			eval {
				my $body = shift;
				my $data = $self->json->decode($body);
				return Future->done($data->{return}) if $data->{success};
				return Future->done({ }) if $data->{error} eq 'not found';

				return Future->fail($data->{error}, 'btc-e')
			} or return Future->fail($@, 'exception');
		})
	})
}

=head2 trade

Attempts to make a trade.

=cut

sub trade {
	my ($self, %args) = @_;

	$self->error_check(sub {
		my $req = $self->build_request(
			method => 'Trade',
			pair   => $args{pair} // 'btc_usd',
			type   => $args{type},
			rate   => $args{rate},
			amount => $args{amount},
		);
		$self->ua->request(
			$req,
			host    => $self->host,
			port => $self->port,
			ssl     => $self->ssl,
		)->then(sub {
			eval {
				my $body = shift;
				my $data = $self->json->decode($body);
				return Future->done($data->{return}) if $data->{success};
				return Future->done({ }) if $data->{error} eq 'not found';

				return Future->fail($data->{error}, 'btc-e')
			} or return Future->fail($@, 'exception');
		})
	})
}

=head2 build_request

Builds a request.

=cut

sub build_request {
	my ($self, @data) = @_;
	unshift @data, nonce  => $self->nonce;
	my $sign = join '&', pairmap { "$a=$b" } @data;
	my $signed = hmac_sha512_hex($sign, $self->secret);

	my $headers = [
		Key => $self->key,
		Sign => $signed,
		"Content-type" => 'application/x-www-form-urlencoded',
		"Content-Length" => length($sign),
		"Host" => $self->host,
	];

	my $req = HTTP::Request->new(
		POST => $self->base_url . '/tapi',
		$headers,
		$sign
	);
	$req->protocol('HTTP/1.1');
	$req
}

=head2 error_check

Wraps requests in basic error checking. Will retry for known cases such as invalid nonce.

=cut

sub error_check {
	my ($self, $code) = @_;
	my $retry = 0;
	retain_future(
		(try_repeat {
			$retry = 0;
			$code->()->else(sub {
				my ($err, $src, @details) = @_;
				return Future->fail($err, $src, @details) unless $src && $src eq 'btc-e';

				if($err =~ /invalid nonce parameter/) {
					($self->{nonce}) = $err =~ /you should send:\s*(\d+)/;
					$log->debugf("Updating nonce to %d and retrying", $self->{nonce});
					$retry = 1;
					return Future->fail($err, nonce => $self->{nonce});
				}
				return Future->fail($err, $src, @details);
			})
		} while => sub { shift->failure && $retry })
	);
}


sub json { shift->{json} //= JSON::MaybeXS->new}

sub key { shift->{key} }

sub secret { shift->{secret} }

sub nonce { (shift->{nonce} //= 1)++ }

sub base_url { ($_[0]->ssl ? 'https://' : 'http://') . $_[0]->host }

sub host { 'btc-e.com' }

sub port { 443 }

sub ssl { 1 }

sub ua { shift->{ua} }

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<https://btc-e.com/tapi/docs> - trading API

=item * L<https://btc-e.com/api/3/docs> - public API

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
