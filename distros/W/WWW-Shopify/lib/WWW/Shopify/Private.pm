#!/usr/bin/perl


=head1 NAME

WWW::Shopify::Private - Main object representing private app access to a particular Shopify store.

=cut

=head1 DESCRIPTION

Inherits all methods from L<WWW::Shopify>, provides additional mechanisms to modify the used password, user-agent and url handler.

=cut

use strict;
use warnings;

package WWW::Shopify::Private;
use parent 'WWW::Shopify';

=head1 METHODS

=head2 new(url, api_key, password)

Creates a new WWW::Shopify::Private object, which allows you to make calls via the shopify private app interface.s

=cut

sub new { 
	my $package = shift;
	my ($shop_url, $api_key, $password, $api_version) = @_;
	my $self = $package->SUPER::new($shop_url,undef,undef,$api_version);
	$self->api_key($api_key);
	$self->password($password);
	return $self;
}

sub url_handler { $_[0]->{_url_handler} = $_[1] if defined $_[1]; return $_[0]->{_url_handler}; }

=head2 encode_url($url)

Modifies the requested url by prepending the api key and the password, as well as the shop's url, before sending the request off to the user agent.

=cut

sub encode_url { 
	my ($self, $url) = @_;
	return "https://" . $self->api_key . ":" . $self->password . "@" . $self->shop_url . $url;
}


=head2 api_key([$api_key])

Gets/sets the app's access token.

=cut

sub api_key { $_[0]->{_api_key} = $_[1] if defined $_[1]; return $_[0]->{_api_key}; }


=head2 password([$new_password])

Gets/sets the app's private password.

=cut

sub password { $_[0]->{_password} = $_[1] if defined $_[1]; return $_[0]->{_password}; }

=head1 SEE ALSO

L<WWW::Shopify::Item>, L<WWW::Shopify>

=head1 AUTHOR

Adam Harrison (adamdharrison@gmail.com)

=head1 LICENSE

See LICENSE in the main directory.

=cut


1;
