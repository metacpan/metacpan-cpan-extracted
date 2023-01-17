#!/usr/bin/perl

=head1 NAME

WWW::Shopify - Main object representing acess to a particular Shopify store.

=cut

=head1 DISCLAIMER

WWW::Shopify is my first official CPAN module, so please bear with me as I try to sort out all the bugs, and deal with the unfamiliar CPAN infrastructure. Don't expect this to work out of the box as of yet, I'm still learning exactly how things are working. Hence some version problems I've been having.

Thanks for your understanding.

=cut

=head1 DESCRIPTION

WWW::Shopify represents a way to grab and upload data to a particular shopify store.
All that's required is the access token for a particular app, its url, and the API key, or altenratively, if you have a private app, you can substitue the app password for the api key.
If you want to use make a private app, use WWW::Shopify::Private. If you want to make a public app, use WWW::Shopify::Public.

=cut

=head1 EXAMPLES

In order to get a list of all products, we can do the following:

	# Here we instantiate a copy of the public API object, with all the necessary fields.
	my $sa = new WWW::Shopify::Public($shop_url, $api_key, $access_token);

	# Here we call get_all, OO style, and specify the entity we want to get.
	my @products = $sa->get_all('Product');

In this way, we can get and modify all the different types of shopify stuffs.

If you don't want to be using a public app, and just want to make a private app, it's just as easy:

	# Here we instantiate a copy of the private API object this time, which means we don't need an access token, we just need a password.
	my $sa = new WWW::Shopify::Private($shop_url, $api_key, $password);
	my @products = $sa->get_all('Product');

Easy enough.

To insert a Webhook, we'd do the following.

	my $webhook = new WWW::Shopify::Model::Webhook({topic => "orders/create", address => $URL, format => "json"});
	$sa->create($Webhook);

And that's all there is to it. To delete all the webhooks in a store, we'd do:

	$sa->delete($_) for ($sa->get_all('Webhook'));

Very easy.

If we want to do something like update an existing product, without getting it, you can simply create a wrapper object to pass to the sub. Let's update a product's title, if all we have
is the product ID.

	$sa->update(WWW::Shopify::Model::Product->new({ id => $product_id, title => "My New Title!" }));

That'll update the product title.

Now, for another example. Let's say we want to get all products that have the letter "A" in their title, and double the weight of all their variants (randomly). This is also very easy.

	my @products = $sa->get_all("Product");
	for my $variant (map { $_->variants } grep { $_->title =~ m/A/ } @products) {
		$variant->weight($variant->weight*2);
		$sa->update($variant);
	}

=cut

use strict;
use warnings;
use LWP::UserAgent;

package WWW::Shopify;

our $VERSION = '1.04';

use WWW::Shopify::Exception;
use WWW::Shopify::Field;
use Module::Find;
use WWW::Shopify::URLHandler;
use WWW::Shopify::Query;
use WWW::Shopify::Login;
use WWW::Shopify::GraphQL;


# Make sure we include all our models so that when people call the model, we actually know what they're talking about.
BEGIN {	eval(join("\n", map { "require $_;" } findallmod WWW::Shopify::Model)); if (my $exp = $@) { die $exp; } }

package WWW::Shopify;

use Date::Parse;

=head1 METHODS

=head2 new($shop_url, [$email, $pass])

Creates a new shop, without using the actual API, uses automated form submission to log in.

=cut

sub new { 
	my ($package, $shop_url, $email, $password, $api_version) = @_;
	die new WWW::Shopify::Exception("Can't create a shop without a shop url.") unless $shop_url;
	$api_version = '2022-04' unless $api_version && ($api_version =~ m/\d\d\d\d-\d\d/ || $api_version =~ m/^unstable$/);
	my $ua = LWP::UserAgent->new( ($^O eq' linux' ? (ssl_opts => {'SSL_version' => 'TLSv12' }) : ()) );
	$ua->cookie_jar({ });
	$ua->timeout(60);
	$ua->agent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.116 Safari/537.36");
	$package = "WWW::Shopify::Login" if $package eq "WWW::Shopify";
	my $self = bless { _shop_url => $shop_url, _ua => $ua, _url_handler => undef, _api_calls => 0, _sleep_for_limit => 0, _retry_on_errors => 0, _last_timestamp => undef, _decode_entities => 1, _api_version => $api_version, _max_call_limit => 40 }, $package;
	$self->{_ql} = new WWW::Shopify::GraphQL($self);
	$self->url_handler(new WWW::Shopify::URLHandler($self));
	return $self;
}


sub version { $_[0]->{_version} = $_[1] if defined $_[1]; return $_[0]->{_version}; }
sub api_calls { $_[0]->{_api_calls} = $_[1] if defined $_[1]; return $_[0]->{_api_calls}; }
sub max_api_calls { $_[0]->{_max_call_limit} = $_[1] if defined $_[1]; return $_[0]->{_max_call_limit}; }
sub url_handler { $_[0]->{_url_handler} = $_[1] if defined $_[1]; return $_[0]->{_url_handler}; }
sub sleep_for_limit { $_[0]->{_sleep_for_limit} = $_[1] if defined $_[1]; return $_[0]->{_sleep_for_limit}; }
sub retry_on_errors { $_[0]->{_retry_on_errors} = $_[1] if defined $_[1]; return $_[0]->{_retry_on_errors}; }
sub last_timestamp { $_[0]->{_last_timestamp} = $_[1] if defined $_[1]; return $_[0]->{_last_timestamp}; }
sub decode_entities { $_[0]->{_decode_entities} = $_[1] if defined $_[1]; return $_[0]->{_decode_entities}; }
sub api_version { $_[0]->{_api_version} = $_[1] if defined $_[1]; return $_[0]->{_api_version}; }
sub include_presentment_prices {
	my ($self, $enabled) = @_;
	if ($enabled) {
		$self->url_handler->default_header('X-Shopify-Api-Features' => 'include-presentment-prices');
	} else {
		$self->url_handler->default_header('X-Shopify-Api-Features' => $self->url_handler->default_header('X-Shopify-Api-Features') =~ s/,\s*include\-presentment\-prices//ri);
	}
}

sub ql { $_[0]->{_ql} = $_[1] if defined $_[1]; return $_[0]->{_ql}; }

=head2 encode_url($url)

Basic url encoding, works the same for public apps or logged-in apps.

=cut

sub encode_url { return "https://" . $_[0]->shop_url . $_[1]; }


=head2 ua([$new_ua])

Gets/sets the user agent we're using to access shopify's api. By default we use LWP::UserAgent, with a timeout of 5 seconds.

PLEASE NOTE: At the very least, with LWP::UserAgent, at least, on my system, I had to force the SSL layer of the agent to use TLSv12, using the line

	LWP::UserAgent->new( ssl_opts => { SSL_version => 'TLSv12' } );

Otherwise, Shopify does some very weird stuff, and some very weird errors are spit out. Just FYI.

=cut

sub ua { $_[0]->{_ua} = $_[1] if defined $_[1]; return $_[0]->{_ua}; }


=head2 shop_url([$shop_url])

Gets/sets the shop url that we're going to be making calls to.

=cut

# Modifiable Attributes
sub shop_url { $_[0]->{_shop_url} = $_[1] if defined $_[1]; return $_[0]->{_shop_url}; }

sub translate_model($) {
	return $_[1] if $_[1] =~ m/WWW::Shopify::Model/;
	return "WWW::Shopify::Model::" . $_[1];
}

sub PULLING_ITEM_LIMIT { return 250; }
#sub CALL_LIMIT_REFRESH { return 60*5; }
#sub CALL_LIMIT_MAX { return 500; }
sub CALL_LIMIT_MAX { return 40; }
sub CALL_LIMIT_LEAK_TIME { return 1; }
sub CALL_LIMIT_LEAK_RATE { return 2; }

sub get_url { return $_[0]->url_handler->get_url($_[1], $_[2], $_[3], $_[4], $_[5]); }
sub post_url { return $_[0]->url_handler->post_url($_[1], $_[2], $_[3], $_[4], $_[5]); }
sub put_url { return $_[0]->url_handler->put_url($_[1], $_[2], $_[3], $_[4], $_[5]); }
sub delete_url { return $_[0]->url_handler->delete_url($_[1], $_[2], $_[3], $_[4], $_[5]); }

use Data::Dumper;
sub use_url {
	my ($self, $type, $url, @args) = @_;
	my $method = lc($type) . "_url";
	my ($decoded, $response);
	$url = $self->encode_url($url);
	eval {
		my $error_count = 0;
		my $repeatable_error = undef;
		do {
			eval {
				if ($self->sleep_for_limit) {
					do { 
						eval { ($decoded, $response) = $self->$method($url, @args); };
						if (my $exp = $@) { 
							die $exp if !ref($exp) || ref($exp) ne 'WWW::Shopify::Exception::CallLimit';
							sleep(1);
						}
					} while (!$response);
				} else {
					($decoded, $response) = $self->$method($url, @args);
				}
			};
			if ($repeatable_error = $@) {
				if (!$self->retry_on_errors || $error_count++ >= $self->retry_on_errors) {
					die $repeatable_error;
				}
			}
		} while ($repeatable_error);
	};
	if (my $exp = $@) {
		print STDERR Dumper($exp->error) if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} > 1;
		die $exp;
	}
	print STDERR uc($type) . " " . $response->request->uri . "\n" if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} == 1;
	print STDERR Dumper($response) if $ENV{'SHOPIFY_LOG'} && $ENV{'SHOPIFY_LOG'} > 1;
	$self->last_timestamp(DateTime->from_epoch( epoch => str2time($response->header('Date'))) ) if $response && $response->header('Date');
	return ($decoded, $response);
}

use Devel::StackTrace;
sub resolve_trailing_url {
	my ($self, $package, $action, $parent, $specs) = @_;
	$package = ref($package) if ref($package);
	my $method = lc($action) . "_through_parent";
	if (($package eq 'WWW::Shopify::Model::Event' && $parent) || ($package->$method && (!$parent || !$parent->is_shop || $package ne "WWW::Shopify::Model::Metafield"))) {
		die new WWW::Shopify::Exception("Cannot resolve URL, no parent specified.") unless $parent;
		if ($package eq "WWW::Shopify::Model::Metafield" && ref($parent) eq 'WWW::Shopify::Model::Product::Image' && $specs) {
			$specs->{"metafield[owner_id]"} = $parent->id;
			$specs->{"metafield[owner_resource]"} = "product_image";
			return "/admin/api/" . $self->api_version . $package->prefix . $package->url_plural;
		}
		# Should be made more generic when I'm sure this won't mess up any other of Shopfy's crazy API.
		if ($package eq 'WWW::Shopify::Model::Order::Fulfillment::FulfillmentEvent') {
			return "/admin/api/" . $self->api_version . $package->prefix . $parent->associated_parent->url_plural . '/' . $parent->associated_parent->id . '/' . $parent->url_plural . '/' . $parent->id . '/' . $package->url_plural;
		} elsif ($package eq 'WWW::Shopify::Model::Event') {
			return "/admin/api/" . $self->api_version . $package->prefix . $parent->associated_parent->url_plural . '/' . $parent->associated_parent->id . '/' . $parent->url_plural . '/' . $parent->id . '/' . $package->url_plural if $parent->associated_parent;
		}
		return "/admin/api/" . $self->api_version . $package->prefix . $parent->url_plural . "/" . $parent->id . "/" . $package->url_plural;
	# I cannot believe that I'm doing this. I don't know why I'm surprised, but it just keeps on going.
	} elsif ($package eq 'WWW::Shopify::Model::ShopifyPayment::Balance::Transaction' && $parent) {
		$specs->{payout_id} = $parent->id;
		return "/admin/api/" . $self->api_version . $package->prefix . $package->url_plural;
	# What the acutal fuck.
	} elsif ($package eq 'WWW::Shopify::Model::Product' && $parent && ref($parent) && ref($parent) =~ m/Collection$/) {
		return "/admin/api/" . $self->api_version . "/collections/" . $parent->id . "/products";
	}
	return "/admin/api/" . $self->api_version . $package->prefix . $package->url_plural;
}

sub get_all_limit {
	my ($self, $package, $specs) = @_;
	$package = $self->translate_model($package);
	$specs->{"limit"} = $package->max_per_page unless exists $specs->{"limit"};
	return () if (defined $specs->{limit} && $specs->{limit} == 0);
	return $self->get_shop if $package->is_shop;
	my $url = $self->resolve_trailing_url($package, "get", $specs->{parent}, $specs) . ".json";
	my ($decoded, $response) = $self->use_url('get', $url, $specs);
	my @return = $self->{_decode_entities} ? (map { my $object = $package->from_json($_, $self); $object->associated_parent($specs->{parent}); $object; } @{$decoded->{$package->plural}}) : @{$decoded->{$package->plural}};
	# The links in the headers come in the form 
	#
	# <https://gift-reggie.myshopify.com/admin/api/2019-10/customers.json?limit=75&page_info=eyJkaXJlY3Rpb24iOiJwcmV2IiwibGFzdF9pZCI6MTA0MTYyOTYxMDAyNywibGFzdF92YWx1ZSI6MTU0MTE4MTU3MzAwMH0>; rel="previous", <https://gift-reggie.myshopify.com/admin/api/2019-10/customers.json?limit=75&page_info=eyJkaXJlY3Rpb24iOiJuZXh0IiwibGFzdF9pZCI6MzM2MTU1NDc2MDA2LCJsYXN0X3ZhbHVlIjoxNTE2MDI3Mjk0MDAwfQ>; rel="next"
	#
	# and we want to extract the page_info string.
	my ($next_page_info) = $response->headers->{link} =~ /.*page_info=([^>|&]*)[^>]*>; rel="next"/  if $response->headers->{link} ;
	my ($prev_page_info) = $response->headers->{link} =~ /.*page_info=([^>|&]*)[^>]*>; rel="previous"/  if $response->headers->{link} ;
	
	return (($next_page_info ? $next_page_info : undef), ($prev_page_info ? $prev_page_info : undef), @return);
}

=head2 get_all($self, $package, $filters)

Gets up to 249 * CALL_LIMIT objects (currently 124750) from Shopify at once. Goes in a loop until it's got everything. Performs a count first to see where it's at.

	@products = $sa->get_all("Product")

If you don't want this behaviour, use the limit filter.

=cut

use POSIX qw/ceil/;
use List::Util qw(min);
sub get_all {
	my ($self, $package, $specs) = @_;
	# objects that still use pageination in 2019-07
	my %v1907 = (
        "AbandonedCheckout" => 1,
        "Article" => 1,
		"Asset" =>1,
        "Blog" => 1,
        "Comment" => 1,
        "CustomCollection" => 1,
        "CustomerAddress" => 1,
        "Customer" => 1,
        "DiscountCode" => 1,
        "Dispute" => 1,
        "DraftOrder" => 1,
        "Fulfillment" => 1,
        "GiftCard" => 1,
        "InventoryItem" => 1,
        "InventoryLevel" => 1,
        "LocationLevel" => 1,
        "MarketingEvent" => 1,
        "Order" => 1,
        "Risk" => 1,
        "Payout" => 1,
        "PriceRule" => 1,
        "Refund" => 1,
        "Report" => 1,
        "SmartCollection" => 1,
        "TenderTransaction" => 1,
        "Transaction" => 1,
        "Webhook" => 1
	);
	return get_all_page(@_) if $self->api_version eq '2019-04' || ($self->api_version eq '2019-07' && $v1907{$package});
	return get_all_cursor(@_);
}

sub get_all_cursor {
    my ($self, $package, $specs, $next_ref, $prev_ref) = @_;
	# We copy our specs so that we don't modify the original hash. Doesn't have to be a deep copy.
	$specs = {%$specs} if $specs;
	$package = $self->translate_model($package);
	$self->validate_item($package);
	return $self->get_shop if $package->is_shop;
	
	my $limit = $specs->{limit};
	$specs->{limit} = defined $limit && $limit < $package->max_per_page ? $limit : $package->max_per_page;
	
	my @return;
	my $callback = $specs->{callback} ? delete $specs->{callback} : undef;
	my $counter = 0;
	my $wantarray = wantarray;
	eval {
		#delete $specs->{page};
		my @chunk;
		my $next_page_info;
		my $prev_page_info;
		do {
			my $real_specs = {%$specs} unless $specs->{page_info};
			$real_specs->{page_info} = $specs->{page_info} if $specs->{page_info};
			$real_specs->{parent} = $specs->{parent} if $specs->{page_info};
			$real_specs->{limit} = $limit ? int($limit) - $counter : $package->max_per_page;
			$real_specs->{limit} = $package->max_per_page if $package->max_per_page && $real_specs->{limit} > $package->max_per_page;
			delete $real_specs->{page_info} unless $real_specs->{page_info};
			($next_page_info, $prev_page_info, @chunk) = $self->get_all_limit($package, $real_specs);
			$callback->(undef, @chunk) if $callback;
			if (defined $wantarray) {
				if (!defined $limit || (int(@chunk) + int(@return) < $limit)) {
					push(@return, @chunk);
				} else {
					push(@return, grep { defined $_ } @chunk[0..($limit - int(@return) - 1)]);
				}
			}
			$specs->{page_info} = $next_page_info;
			$$next_ref = $next_page_info if $next_ref;
			$$prev_ref = $prev_page_info if $prev_ref;
			
			$counter += int(scalar(@chunk));
		} while ( (!defined $specs->{limit} || int(scalar(@chunk)) == $specs->{limit}) && (!defined $limit || $counter < $limit) && $specs->{page_info});
	};
	if (my $exception = $@) {
		$exception->extra(\@return) if ref($exception) && $exception->isa('WWW::Shopify::Exception::CallLimit');
		die $exception;
	}
	return @return if wantarray;
	return $return[0];
}

#Used for legacy page based pagination or non paginated objects like Assets
sub get_all_page {
    my ($self, $package, $specs) = @_;
	# We copy our specs so that we don't modify the original hash. Doesn't have to be a deep copy.
	$specs = {%$specs} if $specs;
	$package = $self->translate_model($package);
	$self->validate_item($package);
	return $self->get_shop if $package->is_shop;
	
	my $limit = $specs->{limit};
	$specs->{limit} = defined $limit && $limit < $package->max_per_page ? $limit : $package->max_per_page;
	
	my @return;
	my $page = $specs->{page};
	my $callback = $specs->{callback} ? delete $specs->{callback} : undef;
	my $counter = 0;
	my $wantarray = wantarray;
	my ($null_next_page_info,$null_prev_page_info);
	eval {
		$specs->{page} = $specs->{page} ? $specs->{page} : 1;
		my @chunk;
		do {
			($null_next_page_info,$null_prev_page_info,@chunk) = $self->get_all_limit($package, $specs);
			$callback->($specs->{page}, @chunk) if $callback;
			if (defined $wantarray) {
				if (!defined $limit || (int(@chunk) + int(@return) < $limit)) {
					push(@return, @chunk);
				} else {
					push(@return, grep { defined $_ } @chunk[0..($limit - int(@return) - 1)]);
				}
			}
			$specs->{page}++;
			$counter += int(@chunk);
		} while (!defined $page && int(@chunk) == $specs->{limit} && (!defined $limit || $counter < $limit));
	};
	if (my $exception = $@) {
		$exception->extra(\@return) if ref($exception) && $exception->isa('WWW::Shopify::Exception::CallLimit');
		die $exception;
	}
	return @return if wantarray;
	return $return[0];
}

=head2 get_access_scopes($self)

Returns a list of scopes that the token has access to.

	my @access_scopes = $sa->get_access_scopes;
	$access_scopes[0]->{handle}

=cut

sub get_access_scopes {
	my ($self) = @_;
	my ($decoded, $response) = $self->use_url('get', "/admin/oauth/access_scopes.json");
	return @{$decoded->{'access_scopes'}};
}


=head2 get_shop($self)

Returns the actual shop object.

	my $shop = $sa->get_shop;

=cut

sub get_shop {
	my ($self) = @_;
	my $package = 'WWW::Shopify::Model::Shop';
	my ($decoded, $response) = $self->use_url('get', "/admin/" . $package->singular() . ".json");
	my $object = $package->from_json($decoded->{$package->singular()}, $self);
	return $object;
}

=head2 get_timestamp($self)

Uses a call to Shopify to determine the DateTime on the shopify server. This can be used to synchronize things without worrying about the 
local clock being out of sync with Shopify.

=cut

sub get_timestamp {
	my ($self) = @_;
	my $ua = $self->ua;
	my ($decoded, $response) = $self->use_url('get', "/admin/shop.json");
	my $date = $response->header('Date');
	my $time = str2time($date);
	return DateTime->from_epoch( epoch => $time );
}

=head2 get_count($self, $package, $filters)

Gets the item count from the shopify store. So if we wanted to count all our orders, we'd do:

	my $order = $sa->get_count('Order', { status => "any" });

It's as easy as that. Keep in mind not all items are countable (who the hell knows why); a glaring exception is assets. Either check the shopify docs, or grep for the sub "countable".

=cut

sub get_count {
	my ($self, $package, $specs) = @_;
	$package = $self->translate_model($package);
	$self->validate_item($package);
	# If it's not countable (sigh), do a binary search to figure out what the count is. Should find it in ln(n), as opposed to n/250
	# This is generally better for stores where this could become an issue.
	# This used to use a binary search to count non-countable objects, but this is broken in cursor based implementation.
	if (!$package->countable) {
		die new WWW::Shopify::Exception("Unable to count $package; it is not marked as countable in Shopify's API.")
	}
	my ($decoded, $response) = $self->use_url('get', $self->resolve_trailing_url($package, "count", $specs->{parent}, $specs) . "/count.json", $specs);
	return $decoded->{'count'};
}

=head2 get($self, $package, $id)

Gets the item from the shopify store. Returns it in local (classed up) form. In order to get an order for example:

	my $order = $sa->get('Order', 142345);

It's as easy as that. If we don't retrieve anything, we return undef.

=cut

sub get {
	my ($self, $package, $id, $specs) = @_;
	$package = $self->translate_model($package);
	$self->validate_item($package);
	# We have a special case for asssets, for some arbitrary reason.
	my ($decoded, $response);
	eval {
		if ($package !~ m/Asset/) {
			($decoded, $response) = $self->use_url('get', $self->resolve_trailing_url($package, "get", $specs->{parent}) . "/$id.json");
		} else {
			die new WWW::Shopify::Exception("MUST have a parent with assets.") unless $specs->{parent};
			($decoded, $response) = $self->use_url('get', "/admin/api/" . $self->api_version . "/themes/" . $specs->{parent}->id . "/assets.json", {'asset[key]' => $id, theme_id => $specs->{parent}->id});
		}
	};
	if (my $exp = $@) {
		return undef if ref($exp) && $exp->isa("WWW::Shopify::Exception::NotFound");
		die $exp;
	}
	if ($self->{_decode_entities}) {
		my $class = $package->from_json($decoded->{$package->singular()}, $self);
		# Wow, this is straight up stupid that sometimes we don't get a 404.
		return undef unless $class;
		$class->associated_parent($specs->{parent});
		return $class;
	} else {
		return $decoded->{$package->singular};
	}
}

=head2 search($self, $package, $item, { query => $query })

Searches for the item from the shopify store. Not all items are searchable, check the API docs, or grep this module's source code and look for the "searchable" sub.

A popular thing to search for is customers by email, you can do so like the following:

	my $customer = $sa->search("Customer", { query => "email:me@example.com" });

=cut

sub search {
	my ($self, $package, $specs) = @_;
	$package = $self->translate_model($package);
	die new WWW::Shopify::Exception("Unable to search $package; it is not marked as searchable in Shopify's API.") unless $package->searchable;
	die new WWW::Shopify::Exception("Must have a query to search.") unless $specs && $specs->{query};
	$self->validate_item($package);

	my ($decoded, $response) = $self->use_url('get', $self->resolve_trailing_url($package, "get", $specs->{parent}) . "/search.json", $specs);

	my @return = ();
	if ($self->{_decode_entities}) {
		foreach my $element (@{$decoded->{$package->plural()}}) {
			my $class = $package->from_json($element, $self);
			$class->associated_parent($specs->{parent}) if $specs->{parent};
			push(@return, $class);
		}
	} else {
		@return = @{$decoded->{$package->plural()}}
	}
	return @return if wantarray;
	return $return[0] if int(@return) > 0;
	return undef;
}

=head2 create($self, $item)

Creates the item on the shopify store. Not all items are creatable, check the API docs, or grep this module's source code and look for the "creatable" sub.

=cut

use List::Util qw(first);
use HTTP::Request::Common;
sub create {
	my ($self, $item, $options) = @_;
	
	$self->validate_item(ref($item));
	my $specs = {};
	my $missing = first { !exists $item->{$_} } $item->creation_minimal;
	die new WWW::Shopify::Exception("Missing minimal creation member: $missing in " . ref($item)) if $missing;
	die new WWW::Shopify::Exception(ref($item) . " requires you to login with an admin account.") if ($item->needs_login && !$item->needs_plus) && !$self->logged_in_admin;
	$specs = $item->to_json();
	my ($decoded, $response) = $self->use_url($item->create_method, $self->resolve_trailing_url(ref($item), "create", $item->associated_parent) . ".json", {$item->singular() => $specs}, $item->needs_login);
	my $element = $decoded->{$item->singular};
	if ($self->{_decode_entities}) {
		my $object = ref($item)->from_json($element, $self);
		$object->associated_parent($item->associated_parent);
		return $object;
	} else {
		return $element;
	}
}

=head2 update($self, $item)

Updates the item from the shopify store. Not all items are updatable, check the API docs, or grep this module's source code and look for the "updatable" sub.

=cut

sub update {
	my ($self, $class) = @_;
	$self->validate_item(ref($class));
	my %mods = map { $_ => 1 } $class->update_fields;
	my $vars = $class->to_json();
	$vars = { $class->singular => {map { $_ => $vars->{$_} } grep { exists $mods{$_} } keys(%$vars)} };

	my ($decoded, $response);
	if (ref($class) =~ m/Asset/) {
		my $url = $self->resolve_trailing_url(ref($class), "update", $class->associated_parent) . ".json";
		($decoded, $response) = $self->use_url($class->update_method, $url, $vars);
	}
	else {
		($decoded, $response) = $self->use_url($class->update_method, $self->resolve_trailing_url($class, "update", $class->associated_parent) . "/" . $class->id . ".json", $vars);
	}

	my $element = $decoded->{$class->singular()};
	if ($self->{_decode_entities}) {
		my $object = ref($class)->from_json($element, $self);
		$object->associated_parent($class->associated_parent);
		return $object;
	} else {
		return $element;
	}
}

=head2 delete($self, $item)

Deletes the item from the shopify store. Not all items are deletable, check the API docs, or grep this module's source code and look for the "deletable" sub.

=cut

sub delete {
	my ($self, $class) = @_;
	$self->validate_item(ref($class));
	if (ref($class) =~ m/Asset/) {
		my $url = $self->resolve_trailing_url(ref($class), "delete", $class->associated_parent) . ".json?asset[key]=" . $class->key;
		$self->use_url($class->delete_method, $url);
	}
	else {
		$self->use_url($class->delete_method, $self->resolve_trailing_url($class, "delete", $class->associated_parent) . "/" . $class->id . ".json");
	}
	return 1;
}

# For simple things like activating, enabling, disabling, that are a simple post to a custom URL.
# Sometimes returns an object, sometimes returns a 1.
use List::Util qw(first);
sub custom_action {
	my ($self, $object, $action) = @_;
	die new WWW::Shopify::Exception("You can't $action " . $object->plural . ".") unless defined $object && first { $_ eq $action } $object->actions;
	my $element;
	my ($decoded, $response);
	if ($object->can('id')) {
		my $id = $object->id;
		my $url = $self->resolve_trailing_url($object, $action, $object->associated_parent) . "/$id/$action.json";
		($decoded, $response) = $self->use_url('post', $url, {$object->singular() => $object->to_json});
		return 1 if !$decoded;
		$element = $decoded->{$object->singular()};
	} else {
		my $url = $self->resolve_trailing_url($object, $action, $object->associated_parent) . "/$action.json";
		($decoded, $response) = $self->use_url('post', $url, $object->to_json);
		return 1 if !$decoded;
		$element = $decoded->{$object->singular()};
	}
	if ($element) {
		$object = ref($object)->from_json($element, $self);
		return $object;
	} else {
		return $decoded;
	}
}

=head2 activate($self, $charge), disable($self, $discount), enable($self, $discount), open($self, $order), close($self, $order), cancel($self, $order)

Special actions that do what they say.

=cut

sub adjust { return $_[0]->custom_action($_[1], "adjust"); }
sub connect { return $_[0]->custom_action($_[1], "connect"); }
sub set { return $_[0]->custom_action($_[1], "set"); }
sub activate { return $_[0]->custom_action($_[1], "activate"); }
sub disable { return $_[0]->custom_action($_[1], "disable"); }
sub enable { return $_[0]->custom_action($_[1], "enable"); }
sub open { return $_[0]->custom_action($_[1], "open"); }
sub close { return $_[0]->custom_action($_[1], "close"); }
sub cancel { return $_[0]->custom_action($_[1], "cancel"); }
sub approve { return $_[0]->custom_action($_[1], "approve"); }
sub remove { return $_[0]->custom_action($_[1], "remove"); }
sub spam { return $_[0]->custom_action($_[1], "spam"); }
sub not_spam { return $_[0]->custom_action($_[1], "not_spam"); }
sub complete { return $_[0]->custom_action($_[1], "complete"); }
sub account_activation_url { return $_[0]->custom_action($_[1], "account_activation_url"); }
sub order { 	
	my ($self, $object, $hash) = @_;
	die new WWW::Shopify::Exception("You can't order " . $object->plural . ".") unless defined $object && first { $_ eq "order" } $object->actions;
	# Mainly for smart collections; no idea why Shopify decides to go against the grain and do something completely different for smart collections against literally everything else.
	# It's a mystery.
	my $url = $self->resolve_trailing_url($object, "order", $object->associated_parent) . "/" . $object->id . "/order.json?";
	if ($hash->{products}) {
		$url .= join("&", map { "products[]=" . (ref($_) ? $_->{id} : $_) } @{$hash->{products}});
	} 
	if ($hash->{sort_order}) {
		$url .= "&" if $url !~ m/\?$/;
		$url .= "sort_order=" . $hash->{sort_order};
	}
	my ($decoded, $response) = $self->use_url('put', $url, {});
	return 1;
}


sub is_valid { eval { $_[0]->get_shop; }; return undef if ($@); return 1; }
sub handleize {
	my ($self, $handle) = @_;
	$handle = $self if !ref($self);
	$handle = lc($handle);
	$handle =~ s/^\s+//;
	$handle =~ s/\s+$//;
	$handle =~ s/\s/-/g;
	$handle =~ s/[^a-z0-9\-]//g;
	$handle =~ s/\-+/-/g;
	return $handle;
}


=head2 create_private_app()

Automates a form submission to generate a private app. Returns a WWW::Shopify::Private with the appropriate credentials. Must be logged in.

=cut

use WWW::Shopify::Private;
use List::Util qw(first);
sub create_private_app {
	my ($self) = @_;
	my $app = $self->create(new WWW::Shopify::Model::APIClient({}));
	my @permissions = $self->get_all("APIPermission");
	my $permission = first { $_->api_client->api_key eq $app->api_key } @permissions;
	return new WWW::Shopify::Private($self->shop_url, $app->api_key, $permission->access_token);
}


=head2 delete_private_app($private_api)

Removes a private app. Must be logged in.

=cut

sub delete_private_app {
	my ($self, $api) = @_;
	my @apps = $self->get_all("APIPermission");
	my $app = first { $_->api_client && $_->api_client->api_key eq $api->api_key } @apps;
	die new WWW::Shopify::Exception("Can't find app with api key " . $api->api_key) unless $app;
	return $self->delete(new WWW::Shopify::Model::APIClient({ id => $app->api_client->id }));
}


# Internal methods.
sub validate_item {
	eval {	die unless $_[1]; $_[1]->is_item; };
	die new WWW::Shopify::Exception($_[1] . " is not an item.") if ($@);
	die new WWW::Shopify::Exception($_[1] . " requires you to login with an admin account.") if ($_[1]->needs_login && !$_[1]->needs_plus)  && !$_[0]->logged_in_admin;
}


=cut

=head1 EXPORTED FUNCTIONS

The functions below are exported as part of the package.

=cut

=head2 calc_webhook_signature($shared_secret, $request_body)

Calculates the webhook_signature based off the shared secret and request body passed in.

=cut

=head2 verify_webhook($shared_secret, $request_body)

Shopify webhook authentication. ALMOST the same as login authentication, but, of course, because this is shopify they've got a different system. 'Cause you know, one's not good enough.

Follows this: http://wiki.shopify.com/Verifying_Webhooks.

=cut

use Exporter 'import';
our @EXPORT_OK = qw(verify_webhook verify_login verify_proxy calc_webhook_signature calc_login_signature calc_hmac_login_signature calc_proxy_signature handleize calc_jwt_signature);
use Digest::MD5 'md5_hex';
use Digest::SHA qw(hmac_sha256_hex hmac_sha256_base64 hmac_sha256);
use MIME::Base64 qw(encode_base64url);

sub calc_webhook_signature {
	my ($shared_secret, $request_body) = @_;
	die new WWW::Shopify::Exception("Requires a shared secret.") unless $shared_secret;
	my $calc_signature = hmac_sha256_base64((defined $request_body) ? $request_body : "", $shared_secret);
	while (length($calc_signature) % 4) { $calc_signature .= '='; }
	return $calc_signature;
}


sub verify_webhook {
	my ($x_shopify_hmac_sha256, $request_body, $shared_secret) = @_;
	return undef unless $x_shopify_hmac_sha256;
	return $x_shopify_hmac_sha256 eq calc_webhook_signature($shared_secret, $request_body);
}

sub calc_jwt_signature {
	my ($shared_secret, $header_and_body) = @_;
	return  encode_base64url(hmac_sha256($header_and_body, $shared_secret));
}

=head2 calc_login_signature($shared_secret, $%params)

Calculates the MD5 login signature based on the shared secret and parmaeter hash passed in. This is deprecated.

=cut

=head2 calc_hmac_login_signature($shared_secret, $%params)

Calculates the SHA256 login signature based on the shared secret and parmaeter hash passed in.

=cut

=head2 verify_login($shared_secret, $%params)

Shopify app dashboard verification (when someone clicks Login on the app dashboard).

This one was kinda random, 'cause they say it's like a webhook, but it's actually like legacy auth.

Also, they don't have a code parameter. For whatever reason.

=cut

sub calc_login_signature {
	my ($shared_secret, $params) = @_;
	return md5_hex($shared_secret . join("", map { "$_=" . $params->{$_} } (sort(grep { $_ ne "signature" } keys(%$params)))));
}

sub calc_hmac_login_signature {
	my ($shared_secret, $params) = @_;
	return hmac_sha256_hex(join("&", map { 
		my $key = $_ =~ s/\[\]//r; 
		(ref($params->{$_}) eq 'ARRAY' ? ($_ !~ m/\[\]$/ ? "$key=" . join(", ", @{$params->{$_}}) : "$key=[" . join(", ", map { "\"$_\"" } @{$params->{$_}}) . "]") : ("$_=" . $params->{$_}))
	} (sort(grep { $_ ne "hmac" && $_ ne "signature" } keys(%$params)))), $shared_secret);
}

sub verify_login {
	my ($shared_secret, $params) = @_;
	return undef unless $params->{hmac};
	my $hmac = ref($params->{hmac}) eq 'ARRAY' ? $params->{hmac}->[0] : $params->{hmac};
	return calc_hmac_login_signature($shared_secret, $params) eq $hmac;
}

=head2 calc_proxy_signature($shared_secret, $%params)

Based on shared secret/hash of parameters passed in, calculates the proxy signature.

=cut

=head2 verify_proxy($shared_secret, %$params)

This is SLIGHTLY different from the above two. For, as far as I can tell, no reason.

=cut

sub calc_proxy_signature {
	my ($shared_secret, $params) = @_;
	return hmac_sha256_hex(join("", sort(map { 
		my $p = $params->{$_};
		"$_=" . (ref($p) eq "ARRAY" ? join(",", @$p) : $p);
	} (grep { $_ ne "signature" } keys(%$params)))), $shared_secret);
}

sub verify_proxy { 
	my ($shared_secret, $params) = @_;
	return undef unless $params->{signature};
	my $signature = ref($params->{signature}) eq 'ARRAY' ? $params->{signature}->[0] : $params->{signature};
	return calc_proxy_signature($shared_secret, $params) eq $signature;
}

=head2 all_items($self)

Returns a list of all publically available items on the store.

=cut

sub all_items {
	my ($package) = @_;
	return grep { $_ ne 'WWW::Shopify::Model::NestedItem' &&  $_ ne 'WWW::Shopify::Model::Item' && !$_->needs_login && (!$_->is_nested || !$_->included_in_parent) } findsubmod WWW::Shopify::Model;
}

=head1 SEE ALSO

L<WWW::Shopify::Public>, L<WWW::Shopify::Private>, L<WWW::Shopify::Test>, L<WWW::Shopify::Item>, L<WWW::Shopify::Common::DBIx>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

Copyright (C) 2020 Adam Harrison

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
