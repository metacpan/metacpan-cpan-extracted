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
	my ($package, $parent, $headers) = @_;
	my $self = bless {_parent => $parent, _default_headers => ($headers || {})}, $package;
	weaken($self->{_parent});
	return $self;
}
sub ua { return $_[0]->parent->ua; }

sub default_header {
	my ($self, $key, $value) = @_;
	$self->{_default_headers}->{$key} = $value if int(@_) >= 3;
	return $self->{_default_headers}->{$key};
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
	$request->header("Accept-Encoding" => "gzip") if !$ENV{"SHOPIFY_LOG"} || $ENV{"SHOPIFY_LOG"} != 2;
	$request->header($_ => $self->{_default_headers}->{$_}) for (keys(%{$self->{_default_headers}}));
	return $self->handle_response($self->request($request));
	
}

sub request {
	my ($self, $request) = @_;
	return $self->ua->request($request);
}

sub handle_response {
	my ($self, $response) = @_;
	if (!$response->is_success) {
		die WWW::Shopify::Exception::CallLimit->new($response) if $response->code() == 429;
		die WWW::Shopify::Exception::InvalidKey->new($response) if $response->code() == 401;
		die WWW::Shopify::Exception::NotFound->new($response) if $response->code() == 404;
		die WWW::Shopify::Exception->new($response);
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
	my $decoded = length($content) >= 2 && (!$response->header('Content-Type') || $response->header('Content-Type') =~ /json/) ? from_json($content) : $content;
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
	$request->header("Accept-Encoding" => "gzip") if !$ENV{"SHOPIFY_LOG"} || $ENV{"SHOPIFY_LOG"} != 2;
	$request->header($_ => $self->{_default_headers}->{$_}) for (keys(%{$self->{_default_headers}}));
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
	my $response = $self->request($request);
	if ($type =~ m/json/) {
		return $self->handle_response($response);
	} else {
		if ($response->is_redirect) {
			
		}
		return (undef, $response);
	}
}

sub upload_url {
	my ($self, $method, $url, $name, $filename, $mime, $contents) = @_;
	my $request = HTTP::Request->new($method, $url);
	my $boundary = '----WebKitFormBoundaryePkpFF7tjBAqx29L';
	$request->header('Content-Type' => 'multipart/form-data; boundary=' . $boundary);
	$request->header('Accept' => 'Accept:application/json, text/javascript, */*; q=0.01');
	$request->content("--" . $boundary . "\r\n" .
	"Content-Disposition: form-data; name=\"$name\"; filename=\"$filename\"\r\n" .
	"Content-Type: $mime\r\n\r\n$contents\r\n--$boundary--");
	return $self->ua->request($request);
}

sub put_url { return shift->use_url("PUT", @_); }
sub post_url { return shift->use_url("POST", @_); }
sub delete_url { return shift->use_url("DELETE", @_); }

1;
