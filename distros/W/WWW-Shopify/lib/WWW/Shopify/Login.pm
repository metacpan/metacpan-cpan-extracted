#!/usr/bin/perl

use strict;
use warnings;
use utf8; 

# All the extra functionality relating to the admin panel should go in here.
package WWW::Shopify::Login;
use parent 'WWW::Shopify';

sub get_all {
	my ($self, $package, $hash) = @_;
	if ($package =~ m/LocaleTranslation/) {
		$hash->{locale_id} = $hash->{parent}->id if $hash->{parent};
	}
	return shift->SUPER::get_all(@_);
}


# Used for the login version.
# X-Shopify-Api-Features:pagination-headers, embed-metafields, include-image-token.
sub embed_metafields { if (defined $_[1]) { $_[0]->{embed_metafields} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{embed_metafields}; }
sub include_image_token {  if (defined $_[1]) { $_[0]->{include_image_token} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{include_image_token}; }
sub pagination_headers { if (defined $_[1]) { $_[0]->{pagination_headers} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{pagination_headers}; }
sub include_variant_summary { if (defined $_[1]) { $_[0]->{include_variant_summary} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{include_variant_summary}; }
sub include_gift_cards { if (defined $_[1]) { $_[0]->{include_gift_cards} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{include_gift_cards}; }
sub future_publishables { if (defined $_[1]) { $_[0]->{future_publishables} = $_[1]; $_[0]->update_x_shopify_api_features; } return $_[0]->{future_publishables}; }

sub two_factor_secret { if (defined $_[1]) { $_[0]->{two_factor_secret} = $_[1]; } return $_[0]->{two_factor_secret}; }

sub x_shopify_api_headers {
	$_[0]->embed_metafields($_[1]);
	$_[0]->include_image_token($_[1]);
	$_[0]->pagination_headers($_[1]);
	$_[0]->include_variant_summary($_[1]);
	$_[0]->include_gift_cards($_[1]);
	$_[0]->future_publishables($_[1]);
}


sub new { 
	my ($package, $shop_url, $email, $password, $two_factor_secret) = @_;
	my $self = $package->SUPER::new($shop_url, $email, $password);
	$self->two_factor_secret($two_factor_secret) if $two_factor_secret;
	$self->login_admin($email, $password, $two_factor_secret) if defined $email && defined $password;
	return $self;
}

sub update_x_shopify_api_features {
	my ($self) = @_;
	my @list = (
		($_[0]->embed_metafields ? ('embed-metafields') : ()),
		($_[0]->pagination_headers ? ('pagination-headers') : ()),
		($_[0]->include_image_token ? ('include-image-token') : ()),
		($_[0]->include_variant_summary ? ('include-variant-summary') : ()),
		($_[0]->include_gift_cards ? ('include-gift-cards') : ()),
		($_[0]->future_publishables ? ('future-publishables') : ()),
	);
	if (int(@list) == 0 && $self->url_handler->{_default_headers}->{'X-Shopify-Api-Features'}) {
		delete $self->url_handler->{_default_headers}->{'X-Shopify-Api-Features'};
		delete $self->url_handler->{_default_headers}->{'X-Requested-With'};
	} elsif (int(@list) > 0) {
		$self->url_handler->{_default_headers}->{'X-Shopify-Api-Features'} = join(", ", @list);
		$self->url_handler->{_default_headers}->{'X-Requested-With'} = "XMLHttpRequest";
	}
}
# Takes in a list of locales.
sub create_update_locale_translation {
	my ($self, @locales) = @_;
	my @english_translation = $self->get_english_translation;
	my %hash = map { $_->english => $_->text } @locales;
	my %mapping = ();
	foreach my $english (@english_translation) {
		$mapping{$english->id} = exists $hash{$english->english} ? $hash{$english->english} : "";
	}
	my $locale_id = $locales[0]->locale_id;
	my ($decoded, $response) = $self->use_url('put', "/admin/locales/$locale_id.json", { s => \%mapping });
	my $package = "WWW::Shopify::Model::Locale";
	my $object = $package->from_json($decoded->{$package->singular}, $self);
	return $object;
}

sub get_english_translation {
	my ($self) = @_;
	my $package = "WWW::Shopify::Model::LocaleTranslation";
	my ($decoded, $response) = $self->use_url('get', "/admin/locale_translations/english_translations.json");
	return map { my $object = $package->from_json($_, $self); $object; } @{$decoded->{$package->plural}};
}

sub update {
	my ($self, $item, $hash) = @_;
	
	if ($item->needs_form_encoding_update) {
		my $response = $self->use_url("POST", $self->resolve_trailing_url($item, "update", $item->associated_parent) . "/" . $item->id, {
			authenticity_token => $self->{authenticity_token},
			utf8 => "✓",
			_method => "patch",
			$item->singular => $item
		}, 1, "application/x-www-form-urlencoded",  "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
		return (undef, $response);
	}	
	return shift->SUPER::update(@_) unless ref($item) =~ m/LocaleTranslation/;
}

sub create {
	my ($self, $item, $hash) = @_;
	
	if ($item->needs_form_encoding_create) {
		my $response = $self->use_url("POST", $self->resolve_trailing_url($item, "create", $item->associated_parent), {
			authenticity_token => $self->{authenticity_token},
			utf8 => "✓",
			$item->singular => $item
		}, 1, "application/x-www-form-urlencoded",  "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
		return (undef, $response);
	}	
	return shift->SUPER::create(@_) unless ref($item) =~ m/LocaleTranslation/;
}


sub delete {
	my ($self, $class) = @_;
	$self->validate_item(ref($class));
	if ($class->needs_form_encoding_delete) {
		$self->use_url("POST", $self->resolve_trailing_url($class, "delete", $class->associated_parent) . "/" . $class->id, {
			_method => "delete",
			authenticity_token => $self->{authenticity_token},
			utf8 => "✓"
		}, 1, "application/x-www-form-urlencoded",  "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
	} else {
		$self->SUPER::delete($class);
	}
	return 1;
}

sub extract_alt_text {
	my ($self, $image, $content) = @_;
	my $product_id = $image->associated_parent->id;
	my $image_id = $image->id;
	my ($form) = ($content =~ m/<form[^>]+action="\/admin\/products\/$product_id\/images\/$image_id"(.*?)<\/form>/ms);
	die new WWW::Shopify::Exception() unless $form =~ m/<input[^>]+name="image\[alt\]" type="text"\s*(?:value="([^"]+)")?\s*\/>/;
	return $1;
}

sub get_alt_text {
	my ($self, $image) = @_;
	die new WWW::Shopify::Exception("Unable to find parent product.") unless $image->associated_parent;
	my $result = $self->use_url("GET", $self->resolve_trailing_url($image->associated_parent, "GET") . "/" . $image->associated_parent->id, { }, "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
	return $self->extract_alt_text($image, $result->decoded_content);
}

sub get_alt_texts {
	my ($self, $product) = @_;
	my $result = $self->use_url("GET", $self->resolve_trailing_url($product, "GET") . "/" . $product->id, { }, "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
	my @alt_texts;
	for my $image ($product->images) {
		my $alt_text = $self->extract_alt_text($image, $result->decoded_content);
		push(@alt_texts, $alt_text);
		$image->{metafields} = [WWW::Shopify::Model::Metafield->new({
			key => 'alt',
			namespace => 'tags',
			value_type => 'string',
			value => $alt_text
		})] if defined $alt_text;
	}
	return @alt_texts;
}

sub send_activation_links {
	my ($self, @customers) = @_;
	my ($decoded, $response) = $self->use_url('put', "/admin/customers/set", { operation => "invite", 'customer_ids[]' => [map { $_->id } @customers] }, 1, "application/x-www-form-urlencoded");
	die  new WWW::Shopify::Exception("Unexpected Response.") unless $decoded->{message} =~ m/Invited (\d+) customer/;
	return $1;
}

sub get_activation_link {
	my ($self, $customer) = @_;
	my ($decoded, $reponse) = $self->use_url('get', "/admin/customers/" . $customer->id, { }, "text/html");
	die new WWW::Shopify::Exception("Unable to find activation link for " . $customer->id . ".") unless $decoded =~ m/http:\/\/[\w\.]+\/account\/activate\/\w+/;
	return $&;
}

sub get_reset_token {
	my ($self, $customer) = @_;
	my ($decoded, $response) = $self->use_url('get', "/admin/customers/" . $customer->id, { }, "text/html");
	die new WWW::Shopify::Exception("Unable to find activation link for " . $customer->id . ".") unless $decoded =~ m/http:\/\/[\w\.]+\/account\/activate\/(\w+)/;
	return $1;
}

sub send_activation_link {
	my ($self, $customer, $from, $subject, $body, $reset_token) = @_;
	my ($decoded, $response) = $self->use_url('post', "/admin/customers/" . $customer->id . "/invite", {
		utf => '✓',
		source => 'adminnext',
		'customer_invite_message[from]' => $from,
		'customer_invite_message[subject]' => $subject,
		'customer_invite_message[body]' => $body,
		'customer_invite_message[reset_token]' => $reset_token
	}, "application/x-www-form-urlencoded");
}


=head2 login_admin($self, $email, $password)

Logs you in to the shop as an admin, allowing you to create and manipulate discount codes, as well as upload files into user-space (not theme space).

Doens't get around the API call limit, unfortunately.

=cut

use HTTP::Request::Common;
sub login_admin {
	my ($self, $username, $password, $secret) = @_;
	$secret = $self->two_factor_secret unless $secret;
	return 1 if $self->{last_login_check} && (time - $self->{last_login_check}) < 1000;
	my $ua = $self->ua;
	die new WWW::Shopify::Exception("Unable to login as admin without a cookie jar.") unless defined $ua->cookie_jar;
	my $res = $ua->get("https://" . $self->shop_url . "/admin/auth/login");
	die new WWW::Shopify::Exception("Unable to get login page.") unless $res->is_success;
	die new WWW::Shopify::Exception("Unable to find authenticity token.") unless $res->decoded_content =~ m/name="authenticity_token".*?value="(\S+)"/ms;
	my $authenticity_token = $1;
	my $req = POST "https://" . $self->shop_url . "/admin/auth/login", [
		login => $username,
		password => $password,
		redirect => "",
		commit => "Log in",
		authenticity_token => $authenticity_token
	];
	$res = $ua->request($req);
	die new WWW::Shopify::Exception("Unable to complete request: " . $res->decoded_content) unless $res->is_success || $res->code == 302;
	if ($res->decoded_content =~ m/Please enter the six/) {
		die new WWW::Shopify::Exception($res) unless $res->decoded_content =~ m/name="authenticity_token" value="(.*?)"/;
		$authenticity_token = $1;
		$self->{authenticity_token} = $authenticity_token;
		$req = POST "https://" . $self->shop_url . "/admin/auth/tfa", [
			code => calc_onetime_code($secret),
			redirect => "",
			commit => "Log in",
			authenticity_token => $authenticity_token
		];
		$res = $ua->request($req);
	}
	die new WWW::Shopify::Exception("Unable to login: $1.") if $res->decoded_content =~ m/class="status system-error">(.*?)<\/div>/;
	$self->{last_login_check} = time;
	$self->{authenticity_token} = $authenticity_token;
	$res = $self->ua->request(GET "https://" . $self->shop_url . "/admin");
	die new WWW::Shopify::Exception($res) unless $res->decoded_content =~ m/meta name="csrf-token" content="(.*?)"/;
	$self->{authenticity_token} = $1;
	$ua->default_header('X-CSRF-Token' => $self->{authenticity_token});
	return 1;
}

=head2 logged_in_admin($self)

Determines whether or not you're logged in to the Shopify store as an admin.

=cut

sub logged_in_admin {
	my ($self) = @_;
	return undef unless $self->{authenticity_token};
	return 1 if $self->{last_login_check} && (time - $self->{last_login_check}) < 1000;
	my $ua = $self->ua;
	return undef unless $ua->cookie_jar;
	my $res = $ua->get('https://' . $self->shop_url . '/admin/discounts/count.json');
	return undef unless $res->is_success;
	$self->{last_login_check} = time;
	return 1;
}

use Exporter 'import';
our @EXPORT_OK = qw(calc_onetime_code);
use Digest::SHA qw(hmac_sha1);
use Convert::Base32 qw(decode_base32);
use Math::BigInt;

sub calc_onetime_code {
	my ($secret, $time) = @_;
	$secret = decode_base32($secret);
	$time = $time || time;
	my $step = 30;
	
	my $T = Math::BigInt->new( int( $time / $step ) );
	( my $hex = $T->as_hex ) =~ s/^0x(.*)/"0"x(16 - length $1) . $1/e;	
	my $bin_code = join( "", map chr hex, $hex =~ /(..)/g );
	my $hash = hmac_sha1($bin_code, $secret);
	my $offset = hex substr unpack( "H*" => $hash ), -1;
	my $dt = unpack("N", substr $hash, $offset, 4);
	return sprintf("%06d", ($dt & 0x7fffffff) % (10 ** 6));
}

1;