package WebService::MtGox;
use 5.008;
use Moo;
use Ouch;
use JSON;
use LWP::UserAgent;

our $VERSION  = '0.05';
our $BASE_URL = 'https://mtgox.com/code';

has user     => (is => 'ro');
has password => (is => 'ro');
has base_url => (is => 'rw', lazy => 1, default => sub { $BASE_URL });
has ua       => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $ua = LWP::UserAgent->new();
    push @{ $ua->requests_redirectable }, 'POST';
    $ua;
  }
);

sub get_ticker {
  my $self = shift;
  my $url  = $self->base_url . "/data/ticker.php";
  my $json = $self->ua->get($url)->content();
  decode_json($json);
}

sub get_depth {
  my $self = shift;
  my $url  = $self->base_url . "/data/getDepth.php";
  my $json = $self->ua->get($url)->content();
  decode_json($json);
}

sub get_trades {
  my $self = shift;
  my $url  = $self->base_url . "/data/getTrades.php";
  my $json = $self->ua->get($url)->content();
  decode_json($json);
}

sub get_balance {
  my $self = shift;
  my $url  = $self->base_url . "/getFunds.php";
  my $json = $self->ua->post($url, { name => $self->user, pass => $self->password })->content();
  decode_json($json);
}

sub buy {
  my $self   = shift;
  my %params = @_;
  my $url    = $self->base_url . "/buyBTC.php";
  my $json = $self->ua->post($url, {
    name   => $self->user,
    pass   => $self->password,
    amount => $params{amount},
    price  => $params{price},
  })->content();
  decode_json($json);
}

sub sell {
  my $self   = shift;
  my %params = @_;
  my $url    = $self->base_url . "/sellBTC.php";
  my $json   = $self->ua->post($url, {
    name   => $self->user,
    pass   => $self->password,
    amount => $params{amount},
    price  => $params{price},
  })->content();
  decode_json($json);
}

sub list {
  my $self   = shift;
  my %params = @_;
  my $url    = $self->base_url . "/getOrders.php";
  my $json   = $self->ua->post($url, {
    name => $self->user,
    pass => $self->password,
  })->content();
  decode_json($json);
}

sub cancel {
  my $self   = shift;
  my %params = @_;
  my $url    = $self->base_url . "/cancelOrder.php";
  my $json   = $self->ua->post($url, {
    name => $self->user,
    pass => $self->password,
    oid  => $params{oid},
    type => $params{type},
  })->content();
  decode_json($json);
}

sub send {
  my $self   = shift;
  my %params = @_;
  my $url    = $self->base_url . "/withdraw.php";
  my $json   = $self->ua->post($url, {
    name   => $self->user,
    pass   => $self->password,
    group1 => 'BTC',
    btca   => $params{bitcoin_address},
    amount => $params{amount}
  })->content();
  decode_json($json);
}

1;

__END__

=head1 NAME

WebService::MtGox - access to mtgox.com's bitcoin trading API

=head1 SYNOPSIS

Creating the client

  use WebService::MtGox;
  my $m = WebService::MtGox->new(
    user     => 'you',
    password => 'secret',
  );

Getting Trade Data

  my $ticker = $m->get_ticker;
  my $depth  = $m->get_depth;

Placing Buy and Sell Orders

  my $r1 = $m->buy(amount => 24, price => 7.77);
  my $r2 = $m->sell(amount => 10, price => 8.12);

Make it AnyEvent+Coro-friendly

  use WebService::MtGox;
  use LWP::Protocol::Coro::http;

Finally, use the command line client, mg

  mg help
  mg ticker

=head1 DESCRIPTION

WebService::MtGox gives you access to MtGox's bitcoin trading API.
With this module, you can get current market data and initiate your
buy and sell orders.

It's great for writing bitcoin trading bots.

=head1 API

=head2  Creation

=head3    WebService::MtGox->new(user => $user, password => $password)

This constructs a WebService::MtGox object.  If C<user> and C<password>
are not provided (or are invalid), you will only be able to get market
information from the API.  You will not be able to buy or sell bitcoins
without a valid MtGox username and password.

=head2  Market Information

The following methods do not require authentication.

=head3    $m->get_ticker

Get the daily lows and highs along with the current price in USD for BTC.

=head3    $m->get_depth

Get a list of the current buy and sell orders.

=head3    $m->get_trades

Get a list of recent trades.

=head2  Buying and Selling

The following methods require authentication.

=head3    $m->get_balance

Get your balance

=head3    $m->buy(amount => $n, price => $p)

Create a buy order.

=head3    $m->sell(amount => $n, price => $p)

Create a sell order.

=head3    $m->list

List all of your open orders.

=head3    $m->cancel(oid => $oid, type => $t)

Cancel an order based on oid and type.
Type may be C<1> for buy or C<2> for sell.

=head3    $m->send(bitcoin_address => $addr, amount => $n)

Use this method to withdraw money from mtgox.

B<NOTICE>:  As of 2011-05-30, this API function has not yet been implemented at
mtgox.com.

=head1 SEE ALSO

=head2  API Documentation

L<https://mtgox.com/support/tradeAPI>

=head2  Other Bitcoin-related Modules

L<Catalyst::Model::Bitcoin>,
L<Finance::Bitcoin>,
L<Finance::MtGox>

(Had I known about Finance::MtGox, I wouldn't have made this module.)

=head2 Command Line Client

Buy and sell bitcoins on mtgox.com from the command line.

L<mg>

=head1 AUTHOR

John BEPPU E<lt>beppu {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
