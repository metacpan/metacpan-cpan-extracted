#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::URLHandler;
use JSON qw(from_json to_json encode_json decode_json);
use Data::Dumper;
use Scalar::Util qw(weaken);
use DateTime;
use Encode;

sub new {
	my ($package, $parent) = @_;
	my $self = bless {_parent => $parent, _default_headers => {}}, $package;
	weaken($self->{_parent});
	return $self;
}
sub parent { $_[0]->{_parent} = $_[1] if defined $_[1]; return $_[0]->{_parent}; }

sub get_url {
	my ($self, $url, $parameters, $type) = @_;
	$type = "application/json" unless $type;
	my $uri = URI->new($url);
	my %filtered = ();
	if ($parameters->{fields} && ref($parameters->{fields}) && ref($parameters->{fields}) eq "ARRAY") {
		$parameters->{fields} = join(",", @{$parameters->{fields}});
	}
	for (keys(%$parameters)) {
		if ($parameters->{$_} && ref($parameters->{$_}) eq "DateTime") {
			$filtered{$_} = $parameters->{$_}->strftime('%Y-%m-%d %H:%M:%S%z')
		}
		elsif ($_ ne "parent") {
			$filtered{$_} = $parameters->{$_};
		}
	}
	$uri->query_form(\%filtered);
	my $request = HTTP::Request->new("GET", $uri);
	$request->header("Accept" => $type);
	$request->header($_ => $self->{_default_headers}->{$_}) for (keys(%{$self->{_default_headers}}));
	my $response = $self->parent->ua->request($request);
	if (!$response->is_success) {
		die new WWW::Shopify::Exception::CallLimit($response) if $response->code() == 429;
		die new WWW::Shopify::Exception::InvalidKey($response) if $response->code() == 401;
		die new WWW::Shopify::Exception::NotFound($response) if $response->code() == 404;
		die new WWW::Shopify::Exception($response);
	}
	my $limit = $response->header('x-shopify-shop-api-call-limit');
	if ($limit) {
		die new WWW::Shopify::Exception("Unrecognized limit.") unless $limit =~ m/(\d+)\/\d+/;
		$self->parent->api_calls($1);
	}
	my $content = $response->decoded_content;
	# From JSON because decodec content is already a perl internal string.
	# Sigh. No. It's not. As per https://rt.cpan.org/Public/Bug/Display.html?id=82963; decoded_content doesn't actually do anything.
	$content = decode("UTF-8", $content) if ($response->header('Content-Type') =~ m/application\/json/);
	my $decoded = !$response->header('Content-Type') || $response->header('Content-Type') =~ /json/ ? from_json($content) : $content;
	return ($decoded, $response);
}

use URI::Escape;
use JSON qw(encode_json);
use Scalar::Util qw(reftype);


sub flatten_object {
	my ($prefix, $object) = @_;
	return map {  
		my $key = $_;
		my @items;
		@items = $object->{$key}->iso8601 if (ref($object) || "") eq "DateTime";
		@items = flatten_object($prefix . $key, $object->{$key}) if reftype($object->{$key}) && reftype($object->{$key}) eq "HASH";
		@items = (map { flatten_object($prefix . "[" . $key . "][]", $_) } @{$object->{$key}}) if reftype($object->{$key}) && reftype($object->{$key}) eq "ARRAY";
		@items = ($prefix . "[" . $key . "]=" . uri_escape_utf8(defined $object->{$key} ? $object->{$key} : '')) if !reftype($object->{$key});
		
		@items;
	} grep { $_ ne "associated_parent" && $_ ne "associated_sa" } keys(%$object);
}

sub use_url{
	my ($self, $method, $url, $hash, $needs_login, $type, $accept) = @_;
	$type = "application/json" unless $type;
	$accept = "application/json" unless $accept;
	my $request = HTTP::Request->new($method, $url);
	$request->header("Accept" => $accept, "Content-Type" => $type);
	if ($type =~ m/json/) {
		$request->content($hash ? encode_json($hash) : undef);
	} else {
		if ($hash) {
			$request->content(join("&", map { 
				if (reftype($hash->{$_}) && reftype($hash->{$_}) eq "HASH") {
					flatten_object($_, $hash->{$_});
				} else {
					my $name = uri_escape_utf8($_); 
					map { $name . "=" . uri_escape_utf8($_) } ($hash->{$_} && ref($hash->{$_}) eq "ARRAY" ? @{$hash->{$_}} : ($hash->{$_})) 
				}
			} keys(%$hash) ));
		}
	}
	my $response = $self->parent->ua->request($request);
	if ($type =~ m/json/) {
		if (!$response->is_success) {
			die new WWW::Shopify::Exception::CallLimit($response) if $response->code() == 429;
			die new WWW::Shopify::Exception::InvalidKey($response) if $response->code() == 401;
			die new WWW::Shopify::Exception($response);
		}
		my $limit = $response->header('x-shopify-shop-api-call-limit');
		if ($limit) {
			die new WWW::Shopify::Exception("Unrecognized limit.") unless $limit =~ m/(\d+)\/\d+/;
			$self->parent->api_calls($1);
		}
		my $content = $response->decoded_content;
		# From JSON because decodec content is already a perl internal string.
		# Sigh. No. It's not. As per https://rt.cpan.org/Public/Bug/Display.html?id=82963; decoded_content doesn't actually do anything.
		$content = decode("UTF-8", $content) if ($response->header('Content-Type') =~ m/application\/json/);
		my $decoded = (length($content) >= 2 && (!$response->header('Content-Type') || $response->header('Content-Type') =~ /json/ ? from_json($content) : undef));
		return ($decoded, $response);
	} else {
		if ($response->is_redirect) {
			
		}
		return (undef, $response);
	}
}
sub put_url { return shift->use_url("PUT", @_); }
sub post_url { return shift->use_url("POST", @_); }
sub delete_url { return shift->use_url("DELETE", @_); }

1;
