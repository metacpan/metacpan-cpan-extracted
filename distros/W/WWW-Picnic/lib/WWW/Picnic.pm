package WWW::Picnic;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Library to access Picnic Supermarket API

use Moo;

use Carp qw( croak );
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5 qw( md5_hex );

use WWW::Picnic::Result::Login;
use WWW::Picnic::Result::User;
use WWW::Picnic::Result::Cart;
use WWW::Picnic::Result::DeliverySlots;
use WWW::Picnic::Result::Search;
use WWW::Picnic::Result::Article;


has user => (
  is => 'ro',
  required => 1,
);


has pass => (
  is => 'ro',
  required => 1,
);


has client_id => (
  is => 'ro',
  default => sub { 30100 },
);


has api_version => (
  isa => sub { $_[0] >= 15 },
  is => 'ro',
  default => sub { 15 },
);


has country => (
  is => 'ro',
  default => sub { 'de' },
);


sub api_endpoint {
  my ( $self ) = @_;
  return sprintf('https://storefront-prod.%s.picnicinternational.com/api/%s', $self->country, "".$self->api_version."");
}

has http_agent => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent($self->http_agent_name);
    return $ua;
  },
);


has http_agent_name => (
  is => 'ro',
  lazy => 1,
  default => sub { 'okhttp/3.12.2' },
);


has picnic_agent => (
  is => 'ro',
  lazy => 1,
  default => sub { '30100;1.15.232-15154' },
);


has picnic_did => (
  is => 'ro',
  lazy => 1,
  default => sub {
    # Generate a random device ID (16 hex chars)
    my @chars = ('0'..'9', 'A'..'F');
    return join '', map { $chars[rand @chars] } 1..16;
  },
);


has json => (
  is => 'ro',
  lazy => 1,
  default => sub { return JSON::MaybeXS->new->utf8 },
);

has _auth_cache => (
  is => 'ro',
  default => sub {{}},
);

sub login {
  my ( $self ) = @_;
  my $url = URI->new(join('/',$self->api_endpoint,'user','login'));
  my $request = HTTP::Request->new( POST => $url );
  $request->header('Accept' => 'application/json');
  $request->header('Content-Type' => 'application/json; charset=UTF-8');
  $request->content($self->json->encode({
    key => $self->user,
    secret => md5_hex($self->pass),
    client_id => $self->client_id,
  }));
  my $response = $self->http_agent->request($request);
  if ($response->is_success) {
    my $auth = $response->header('X-Picnic-Auth');
    my $data = $self->json->decode($response->content);
    $data->{auth_key} = $auth;
    if ($auth && $data->{user_id} && !$data->{second_factor_authentication_required}) {
      $self->_auth_cache->{auth} = $auth;
      $self->_auth_cache->{time} = time;
      $self->_auth_cache->{user_id} = $data->{user_id};
    }
    return WWW::Picnic::Result::Login->new($data);
  } else {
    croak __PACKAGE__.": login failed! ".$response->status_line;
  }
}


sub generate_2fa_code {
  my ( $self, $channel ) = @_;
  $channel //= 'SMS';
  my $url = URI->new(join('/',$self->api_endpoint,'user','2fa','generate'));
  my $request = HTTP::Request->new( POST => $url );
  $request->header('Accept' => 'application/json');
  $request->header('Content-Type' => 'application/json; charset=UTF-8');
  $request->content($self->json->encode({ channel => $channel }));
  my $response = $self->http_agent->request($request);
  unless ($response->is_success) {
    croak __PACKAGE__.": 2FA code generation failed! ".$response->status_line;
  }
  return 1;
}


sub verify_2fa_code {
  my ( $self, $code ) = @_;
  croak __PACKAGE__.": 2FA code required" unless defined $code;
  my $url = URI->new(join('/',$self->api_endpoint,'user','2fa','verify'));
  my $request = HTTP::Request->new( POST => $url );
  $request->header('Accept' => 'application/json');
  $request->header('Content-Type' => 'application/json; charset=UTF-8');
  $request->content($self->json->encode({ otp => $code }));
  my $response = $self->http_agent->request($request);
  if ($response->is_success) {
    my $auth = $response->header('X-Picnic-Auth');
    croak __PACKAGE__.": 2FA verify success, but no auth token!" unless $auth;
    my $data = $self->json->decode($response->content);
    $self->_auth_cache->{auth} = $auth;
    $self->_auth_cache->{time} = time;
    $self->_auth_cache->{user_id} = $data->{user_id} if $data->{user_id};
    return 1;
  } else {
    croak __PACKAGE__.": 2FA verification failed! ".$response->status_line;
  }
}


sub picnic_auth {
  my ( $self ) = @_;
  unless (defined $self->_auth_cache->{auth}) {
    my $login = $self->login;
    if ($login->requires_2fa) {
      croak __PACKAGE__.": 2FA required! Call login() and handle 2FA flow manually.";
    }
    unless ($self->_auth_cache->{auth}) {
      croak __PACKAGE__.": login failed to obtain auth token!";
    }
  }
  return $self->_auth_cache->{auth};
}


sub request {
  my ( $self, @original_args ) = @_;
  my ( $method, $path, $data, %params ) = @original_args;
  $data = [] if $method eq 'PUT' and !$data;
  my $url = URI->new(join('/',$self->api_endpoint,$path));
  if (%params) {
    $url->query_form(%params);
  }
  my $request = HTTP::Request->new( $method => $url );
  $request->header('Accept' => 'application/json');
  $request->header('X-Picnic-Auth' => $self->picnic_auth );
  $request->header('X-Picnic-Agent' => $self->picnic_agent );
  $request->header('X-Picnic-Did' => $self->picnic_did );
  if (defined $data) {
    $request->header('Content-Type' => 'application/json');
    $request->content($self->json->encode($data));
  }
  my $response = $self->http_agent->request($request);
  unless ($response->is_success) {
    croak __PACKAGE__.": request to ".$url->as_string." failed! ".$response->status_line;
  }
  return $self->json->decode($response->content);
}


sub get_user {
  my ( $self ) = @_;
  return WWW::Picnic::Result::User->new( $self->request( GET => 'user' ) );
}


sub get_cart {
  my ( $self ) = @_;
  return WWW::Picnic::Result::Cart->new( $self->request( GET => 'cart' ) );
}


sub clear_cart {
  my ( $self ) = @_;
  return WWW::Picnic::Result::Cart->new( $self->request( POST => 'cart/clear' ) );
}


sub get_delivery_slots {
  my ( $self ) = @_;
  return WWW::Picnic::Result::DeliverySlots->new( $self->request( GET => 'cart/delivery_slots' ) );
}


sub search {
  my ( $self, $term ) = @_;
  return WWW::Picnic::Result::Search->new( $self->request( GET => 'pages/search-page-results', undef, search_term => $term ) );
}


sub get_article {
  my ( $self, $product_id ) = @_;
  return WWW::Picnic::Result::Article->new( $self->request( GET => "articles/$product_id" ) );
}


sub add_to_cart {
  my ( $self, $product_id, $count ) = @_;
  $count //= 1;
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/add_product', { product_id => $product_id, count => $count } )
  );
}


sub remove_from_cart {
  my ( $self, $product_id, $count ) = @_;
  $count //= 1;
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/remove_product', { product_id => $product_id, count => $count } )
  );
}


sub set_delivery_slot {
  my ( $self, $slot_id ) = @_;
  return WWW::Picnic::Result::Cart->new(
    $self->request( POST => 'cart/set_delivery_slot', { slot_id => $slot_id } )
  );
}


sub get_categories {
  my ( $self, $depth ) = @_;
  $depth //= 0;
  return $self->request( GET => 'my_store', undef, depth => $depth );
}


sub get_suggestions {
  my ( $self, $term ) = @_;
  return $self->request( GET => 'suggest', undef, search_term => $term );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Picnic - Library to access Picnic Supermarket API

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    use WWW::Picnic;

    my $picnic = WWW::Picnic->new(
        user => 'user@universe.org',
        pass => 'alohahey',
        country => 'de',
    );

    # Explicit login with 2FA support
    my $login = $picnic->login;
    if ($login->requires_2fa) {
        $picnic->generate_2fa_code;
        print "Enter SMS code: ";
        my $code = <STDIN>;
        chomp $code;
        $picnic->verify_2fa_code($code);
    }

    # Search for products
    my $results = $picnic->search('apple');

    # Get your cart
    my $cart = $picnic->get_cart;

    # Get available delivery slots
    my $slots = $picnic->get_delivery_slots;

=head1 DESCRIPTION

B<WORK IN PROGRESS>

This module provides a Perl interface to the Picnic Supermarket API. It handles
authentication and provides methods to search for products, manage your cart,
and check delivery slots.

B<Note:> The module will eventually get classes for the results. If you use this
now, please be aware that the return values will change.

=head2 user

Login email address for your Picnic account. Required.

=head2 pass

Password for your Picnic account. Required.

=head2 client_id

Client identifier for API requests. Defaults to C<30100> (Android app).

=head2 api_version

Picnic API version number. Must be 15 or higher. Defaults to C<15>.

=head2 country

Two-letter country code for your Picnic account. Supported values are C<de> (Germany)
and C<nl> (Netherlands). Defaults to C<de>.

=head2 http_agent

L<LWP::UserAgent> instance used for making HTTP requests to the Picnic API.
Automatically created with the User-Agent string from L</http_agent_name>.

=head2 http_agent_name

User-Agent string sent with HTTP requests. Defaults to C<okhttp/3.12.2> to mimic
the Picnic mobile app.

=head2 picnic_agent

Picnic agent identifier string. Defaults to Android app version.

=head2 picnic_did

Picnic device identifier. Auto-generated random hex string if not provided.

=head2 login

    my $login = $picnic->login;
    if ($login->requires_2fa) {
        # Handle 2FA
    }

Authenticates with the Picnic API. Returns a L<WWW::Picnic::Result::Login>
object that indicates whether two-factor authentication is required.

If 2FA is not required, the auth token is cached automatically.

=head2 generate_2fa_code

    $picnic->generate_2fa_code;
    $picnic->generate_2fa_code('SMS');  # explicit channel

Request a 2FA code to be sent via SMS (default) or another channel.
Call this after L</login> returns a result requiring 2FA.

=head2 verify_2fa_code

    $picnic->verify_2fa_code('123456');

Verify the 2FA code received via SMS. On success, the auth token is
cached and you can proceed with API calls.

=head2 picnic_auth

    my $token = $picnic->picnic_auth;

Authenticates with the Picnic API using the provided L</user> and L</pass>.
Returns the authentication token (C<X-Picnic-Auth> header value). The token
is cached after the first successful authentication.

B<Note:> If 2FA is required, this method will croak. Use L</login> instead
and handle the 2FA flow manually.

This method is called automatically by L</request>, so you typically don't
need to call it directly.

=head2 request

    my $result = $picnic->request($method, $path, $data, %params);

Makes an authenticated HTTP request to the Picnic API. Returns the decoded JSON response.

Parameters:

=over 4

=item * C<$method> - HTTP method (GET, POST, PUT, etc.)

=item * C<$path> - API endpoint path (relative to api_endpoint)

=item * C<$data> - Optional hashref/arrayref to send as JSON body

=item * C<%params> - Optional query parameters

=back

This is a low-level method used internally by other methods. You typically won't
need to call it directly unless accessing undocumented API endpoints.

=head2 get_user

    my $user = $picnic->get_user;
    say $user->firstname, " ", $user->lastname;

Returns a L<WWW::Picnic::Result::User> object with your account details.

=head2 get_cart

    my $cart = $picnic->get_cart;
    say "Items: ", $cart->total_count;
    say "Total: ", $cart->total_price / 100, " EUR";

Returns a L<WWW::Picnic::Result::Cart> object with your shopping cart contents.

=head2 clear_cart

    my $cart = $picnic->clear_cart;

Removes all items from your shopping cart. Returns the updated
L<WWW::Picnic::Result::Cart> object.

=head2 get_delivery_slots

    my $slots = $picnic->get_delivery_slots;
    for my $slot ($slots->available_slots) {
        say $slot->window_start, " - ", $slot->window_end;
    }

Returns a L<WWW::Picnic::Result::DeliverySlots> object with available
delivery time slots for your current cart.

=head2 search

    my $results = $picnic->search('haribo');
    for my $item ($results->all_items) {
        say $item->name, " - ", $item->display_price;
    }

Search for products by name or term. Returns a L<WWW::Picnic::Result::Search>
object containing the results.

=head2 get_article

    my $article = $picnic->get_article($product_id);
    say $article->name;
    say $article->description;

Get detailed information about a specific product. Returns a
L<WWW::Picnic::Result::Article> object.

=head2 add_to_cart

    my $cart = $picnic->add_to_cart($product_id);
    my $cart = $picnic->add_to_cart($product_id, 3);  # add 3 items

Add a product to your shopping cart. Optionally specify quantity (default: 1).
Returns the updated L<WWW::Picnic::Result::Cart> object.

=head2 remove_from_cart

    my $cart = $picnic->remove_from_cart($product_id);
    my $cart = $picnic->remove_from_cart($product_id, 2);  # remove 2 items

Remove a product from your shopping cart. Optionally specify quantity (default: 1).
Returns the updated L<WWW::Picnic::Result::Cart> object.

=head2 set_delivery_slot

    my $cart = $picnic->set_delivery_slot($slot_id);

Select a delivery slot for your order. Returns the updated
L<WWW::Picnic::Result::Cart> object.

=head2 get_categories

    my $categories = $picnic->get_categories;
    my $categories = $picnic->get_categories(2);  # with depth

Get product categories. Optionally specify depth for nested categories.
Returns raw API response (categories structure varies).

=head2 get_suggestions

    my $suggestions = $picnic->get_suggestions('app');

Get search suggestions for a partial search term. Returns raw API response.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-picnic/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
