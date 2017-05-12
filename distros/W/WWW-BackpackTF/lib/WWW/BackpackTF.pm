package WWW::BackpackTF;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;
our $VERSION = '0.002001';
our @EXPORT_OK = qw/TF2 DOTA2 CSGO/;

use constant +{ ## no critic (Capitalization)
	TF2 => 440,
	DOTA2 => 570,
	CSGO => 730,
	QUALITIES => [qw/Normal Genuine rarity2 Vintage rarity3 Unusual Unique Community Valve Self-Made Customized Strange Completed Haunted Collector's/],
};

BEGIN {
	my @qualities = @{QUALITIES()};
	for (0 .. $#qualities) {
		my $name = uc $qualities[$_];
		$name =~ y/A-Z0-9//cd;
		push @EXPORT_OK, $name;
		constant->import($name, $_)
	}
}

use JSON::MaybeXS qw/decode_json/;
use HTTP::Tiny;
use PerlX::Maybe;
use WWW::BackpackTF::Currency;
use WWW::BackpackTF::Item;
use WWW::BackpackTF::MarketItem;
use WWW::BackpackTF::Listing;
use WWW::BackpackTF::User;

my $ht = HTTP::Tiny->new(agent => "WWW-BackpackTF/$VERSION");

sub request {
	my ($self, $url, %params) = @_;
	$params{key} = $self->{key} if $self->{key};
	$url = $self->{base} . $url;
	$url .= "&$_=$params{$_}" for keys %params;
	my $htr = $ht->get($url);
	die $htr->{reason} unless $htr->{success}; ## no critic (RequireCarping)
	my $response = decode_json($htr->{content})->{response};
	die $response->{message} unless $response->{success}; ## no critic (RequireCarping)
	$response
}

sub new{
	my ($class, %args) = @_;
	$args{base} //= 'http://backpack.tf/api/';
	bless \%args, $class
}

sub get_prices {
	my ($self, $appid, $raw) = @_;
	my $response = $self->request('IGetPrices/v4/?compress=1', maybe appid => $appid, maybe raw => $raw);
	map { WWW::BackpackTF::Item->new($_, $response->{items}{$_}) } keys %{$response->{items}}
}

sub get_users {
	my ($self, @users) = @_;
	my $response = $self->request('IGetUsers/v3/?compress=1', steamids => join ',', @users);
	@users = map { WWW::BackpackTF::User->new($_) } values %{$response->{players}};
	wantarray ? @users : $users[0]
}

sub get_currencies {
	my ($self, $appid) = @_;
	my $response = $self->request('IGetCurrencies/v1/?compress=1', maybe appid => $appid);
	map { WWW::BackpackTF::Currency->new($_, $response->{currencies}{$_}) } keys %{$response->{currencies}};
}

# get_price_history not implemented
# get_special_items not implemented

sub get_market_prices {
	my ($self, $appid) = @_;
	my $response = $self->request('IGetMarketPrices/v1/?compress=1', maybe appid => $appid);
	map { WWW::BackpackTF::MarketItem->new($_, $response->{items}{$_}) } keys %{$response->{items}}
}

sub get_user_listings {
	my ($self, $steamid, $appid) = @_;
	my $response = $self->request('IGetUserListings/v2/?compress=1', steamid => $steamid, maybe appid => $appid);
	map { WWW::BackpackTF::Listing->new($_) } @{$response->{listings}}
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF - interface to the backpack.tf trading service

=head1 SYNOPSIS

  use WWW::BackpackTF;
  my $api_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  my $user_id = <STDIN>;
  my $bp = WWW::BackpackTF->new($api_key);
  my $user = $bp->get_users($user_id);
  print 'This user is named ', $user->name, ' and has ', $user->notifications, ' unread notification(s)';
  my @all_items_in_dota2 = $bp->get_prices(WWW::BackpackTF::DOTA2);
  my @currencies = $bp->get_currencies;
  print 'The first currency is ', $currencies[0]->name;

=head1 DESCRIPTION

WWW::BackpackTF is an interface to the backpack.tf Team Fortress 2/Dota 2/Counter-Strike: Global Offensive trading service.

=head2 METHODS

=over

=item B<new>([key => I<$api_key>], [base => I<$base_url>])

Create a new WWW::BackpackTF object. Takes a hash of parameters. Possible parameters:

=over

=item B<key>

The API key. Defaults to nothing. Most methods require an API key.

=item B<base>

The base URL. Defaults to http://backpack.tf/api/.

=back

=item B<get_prices>([I<$appid>, [I<$raw>]])

Get price information for all items. Takes two optional parameters. The first parameter is the appid and defaults to WWW::BackpackTF::TF2. The second (if true) adds a value_raw property to prices and defaults to false. Returns a list of L<WWW::BackpackTF::Item> objects.

=item B<get_users>(I<@users>)

Get profile information for a list of users. Takes any number of 64-bit Steam IDs as arguments and returns a list of L<WWW::BackpackTF::User> objects. This method does not require an API key. Dies with an error message if the operation is unsuccessful.

=item B<get_currencies>([I<$appid>])

Get currency information. Takes one optional parameter, the appid, which defaults to WWW::BackpackTF::TF2. Returns a list of L<WWW::BackpackTF::Currency> objects.

=item B<get_market_prices>([I<$appid>])

Get Steam Community Market price information for all items. Takes one optional parameter, the appid, which defaults to WWW::BackpackTF::TF2. Returns a list of L<WWW::BackpackTF::MarketItem> objects.

=item B<get_user_listings>(I<$steamid>, [I<$appid>])

Get classified listing of a given user. Takes a mandatory 64-bit Steam ID of the user, and an optional parameter, the appid, which defaults to WWW::BackpackTF::TF2. Returns a list of L<WWW::BackpackTF::Listing> objects.

=back

=head2 EXPORTS

None by default.

=over

=item B<TF2>

Constant (440) representing Team Fortress 2.

=item B<DOTA2>

Constant (570) representing Dota 2.

=item B<CSGO>

Constant (730) representing Counter-Strike: Global Offensive

=item B<NORMAL>

The Normal item quality (0).

=item B<GENUINE>

The Genuine item quality (1).

=item B<RARITY2>

The unused rarity2 item quality (2).

=item B<VINTAGE>

The Vintage item quality (3).

=item B<RARITY3>

The unused rarity3 item quality (4).

=item B<UNUSUAL>

The Unusual item quality (5).

=item B<UNIQUE>

The Unique item quality (6).

=item B<COMMUNITY>

The Community item quality (7).

=item B<VALVE>

The Valve item quality (8).

=item B<SELFMADE>

The Self-Made item quality (9).

=item B<CUSTOMIZED>

The unused Customized item quality (10).

=item B<STRANGE>

The Strange item quality (11).

=item B<COMPLETED>

The Completed item quality (12).

=item B<HAUNTED>

The Haunted item quality (13).

=item B<COLLECTORS>

The Collector's item quality (14).

=back

=head1 SEE ALSO

L<http://backpack.tf/>, L<http://backpack.tf/api>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
