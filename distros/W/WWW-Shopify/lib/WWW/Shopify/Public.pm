#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

=head1 NAME

WWW::Shopify::Public - Main object representing public app access to a particular Shopify store.

=cut

=head1 DESCRIPTION

Inherits all methods from L<WWW::Shopify>, provides additional mechanisms to modify the used access_token, user-agent and url handler.

=cut

package WWW::Shopify::Public;
use parent 'WWW::Shopify';

=head1 METHODS

=head2 new($url, $api_key, $access_token)

Creates a new WWW::Shopify::Public object, which allows you to make calls via the shopify public app interface.

You can see an overview of the authentication workflow for a public app here: L<< http://api.shopify.com/authentication.html >> 

=cut

sub new { 
	my $class = shift;
	my ($shop_url, $api_key, $access_token, $api_version) = @_;
	my $self = $class->SUPER::new($shop_url,undef,undef,$api_version);
	# This is an optional addition; it's not necessary.
	$self->api_key($api_key);
	$self->access_token($access_token);
	$self->ua->default_header("X-Shopify-Access-Token" => $access_token);
	return $self;
}

=head2 api_key([$api_key])

Gets/sets the app's access token.

=cut

sub api_key { $_[0]->{_api_key} = $_[1] if defined $_[1]; return $_[0]->{_api_key}; }

=head2 access_token([$access_token])

Gets/sets the app's access token.

=cut

sub access_token { $_[0]->{_access_token} = $_[1] if defined $_[1]; return $_[0]->{_access_token}; }

sub is_valid { my $self = shift; $self->SUPER::is_valid(@_); return $self->{_access_token}; }

=head2 authorize_url(@$scope, $redirect)

When the shop doesn't have an access_token, this is what you should be redirecting your client to. Inputs should be your scope, as an array, and the url you want to redirect to.

=cut

use URI::Escape;
sub authorize_url {
	my ($self, $scope, $redirect, $nonce, $options) = @_;
	my $hostname = $self->shop_url;
	my %parameters = (
		'client_id' => $self->api_key,	
		'scope' => join(",", @$scope),
		'redirect_uri' => $redirect,
		($nonce ? ('state' => $nonce) : ()),
		($options ? ('grant_options[]' => $options) : ())
	);
	return "https://$hostname/admin/oauth/authorize?" . join("&", map { my $key = $_; ref($parameters{$key}) ? (map { "$key=" . uri_escape($_) } @{$parameters{$key}}) : ("$key=" . uri_escape($parameters{$key})) } keys(%parameters));
}

=head2 scope_compare(@$scope1, @$scope2)
	
Determines whether scope1 is more or less permissive than scope2. If the scopes cannot be compared easily
(e.g. [write_orders, read_products], [read_products, write_script_tag]),  then undef is returned. If scopes
can be compared, returns -1, 0 or 1 as appropriate.

=cut

use Exporter 'import';
our @EXPORT_OK = qw(scope_compare scope_clean verify_install calc_hmac_install_signature);

use List::MoreUtils qw(uniq);

sub scope_compare {
	my ($scope1, $scope2) = @_;
	die new WWW::Shopify::Exception("Invalid scopes passed to compare.") unless ref($scope1) && ref($scope2) && ref($scope1) eq "ARRAY" && ref($scope2) eq "ARRAY";
	
	$scope1 = scope_clean($scope1);
	$scope2 = scope_clean($scope2);
	# If scope2 has more permission settings than scope1, we've jumped up in permissions.
	return 1 if int(@$scope1) < int(@$scope2);
	return -1 if (int(@$scope1) > int(@$scope2));
	# Here, we should have exactly equal amounts of scopes in both arrays, sorted. So they should be the same types down.	
	
	for (0..int(@$scope1)-1) {
		die new WWW::Shopify::Exception("Invalid scope: $_") unless $scope1->[$_] =~ m/(read|write)_(\w+)/;
		my ($scope1_permission, $scope1_type) = ($1, $2);
		die new WWW::Shopify::Exception("Invalid scope: $_") unless $scope2->[$_] =~ m/(read|write)_(\w+)/;
		my ($scope2_permission, $scope2_type) = ($1, $2);
		# If we have not the same type, that means we've got some weird permissions going on, so we return undef, because it's
		# neither less nor more permissive, necessarily, just different.
		return undef unless $scope1_type eq $scope2_type;
		# When we've jumped down to a read in our second scope, we're less permissive.
		return -1 if $scope2_permission eq "read" && $scope1_permission eq "write";
		# When we've jumped up to a write in our 
		return 1 if $scope1_permission eq "read" && $scope2_permission eq "write";
	}
	return 0;
}

# TODO There are probably still edge cases here. We should check this more thourghly 
# namely we should probably be checking for string starts with write m/^write_.*/
sub scope_clean {
	my ($scope) = @_;
	
	my @writes = grep { $_ =~ m/write_.*/ } @$scope;
	my @reads = grep { $_ =~ m/read_.*/ } @$scope;
	
	my @fscopes = @writes;
	
	for my $p (@reads) {
		$p =~ m/read_(.*)/;
		my $a = $1;
		push(@fscopes, $p) unless (grep { $_ eq "write_" . $1 } @writes);
	}
	@fscopes = sort(@fscopes);
	return \@fscopes;
}

=head2 refresh_token($new_secret, $refresh_token)

Refreshes a token.

=cut 


sub refresh_token {
	my ($self, $new_secret, $refresh_token) = (@_);
	
	my $req = HTTP::Request->new(POST => "https://" . $self->shop_url . "/admin/oauth/access_token");
  	$req->content_type('application/x-www-form-urlencoded');
	my %parameters = (
		'client_id' => $self->api_key,
		'client_secret' => $new_secret,
		'refresh_token' => $refresh_token,
		'access_token' => $self->access_token
	);
	$req->content(join("&", map { "$_=" . uri_escape($parameters{$_}) } keys(%parameters)));
	my $res;
	my $success = undef;
	for (my $i = 0; $i < 5 && !$success; ++$i) {
		$res = $self->url_handler->request($req);
		$success = $res->is_success();
		sleep 1 unless $success;
	}
	die new WWW::Shopify::Exception("Unable to reach server for https://" . $self->shop_url . "/admin/oauth/access_token: " . $res->code() . ".\n" . $res->content) unless $res->is_success();
	my $decoded = JSON::decode_json($res->content);
	die new WWW::Shopify::Exception("Unable to refresh access token.") unless defined $decoded->{access_token};
	return %{$decoded} if wantarray;
	return $decoded->{access_token};
}

=head2 exchange_token($shared_secret, $code)

When you have a temporary code, which you should get from authorize_url's redirect and you want to exchange it for a token, you call this.

=cut

sub exchange_token {
	my ($self, $shared_secret, $code) = (@_);
	
	my $req = HTTP::Request->new(POST => "https://" . $self->shop_url . "/admin/oauth/access_token");
  	$req->content_type('application/x-www-form-urlencoded');
	my %parameters = (
		'client_id' => $self->api_key,
		'client_secret' => $shared_secret,
		'code' => $code
	);
	$req->content(join("&", map { "$_=" . uri_escape($parameters{$_}) } keys(%parameters)));
	my $res;
	# If you go through the install too fast, Shopify will give you an access denied thing. So in that case, let's repeat until 
	my $success = undef;
	for (my $i = 0; $i < 5 && !$success; ++$i) {
		$res = $self->url_handler->request($req);
		$success = $res->is_success();
		sleep 1 unless $success;
	}
	die new WWW::Shopify::Exception("Unable to reach server for https://" . $self->shop_url . "/admin/oauth/access_token: " . $res->code() . ".\n" . $res->content) unless $res->is_success();
	my $decoded = JSON::decode_json($res->content);
	die new WWW::Shopify::Exception("Unable to retrieve access token.") unless defined $decoded->{access_token};
	return %{$decoded} if wantarray;
	return $decoded->{access_token};
}


sub calc_hmac_install_signature { return WWW::Shopify::calc_hmac_login_signature(@_); }
sub verify_install {
	my ($shared_secret, $params) = @_;
	return undef unless $params->{hmac};
	my $hmac = ref($params->{hmac}) eq 'ARRAY' ? $params->{hmac}->[0] : $params->{hmac};
	return calc_hmac_install_signature($shared_secret, $params) eq $hmac;
}

=head1 SEE ALSO

L<WWW::Shopify::Item>, L<WWW::Shopify>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

See LICENSE in the main directory.

=cut

1;
