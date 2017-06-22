package Webservice::OVH::Order::Hosting::Web;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Hosting::Web

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $free_email_info = $ovh->order->hosting->web->free_email_info;

=head1 DESCRIPTION

Provides the possibility to activate the free hostig package.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.41;

=head2 _new

Internal Method to create the Web object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order::Hosting::Web>

=item * Synopsis: Webservice::OVH::Order::Hosting::Web->_new($ovh_api_wrapper, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper }, $class;

    return $self;
}

=head2 free_email_info

Gets information if free webhosting is available.

=over

=item * Parameter: $domain - target domain for free webhosting

=item * Return: HASH

=item * Synopsis: Webservice::OVH::Order::Hosting::Web->_new('mydomain.de');

=back

=cut

sub free_email_info {

    my ( $self, $domain ) = @_;

    croak "Missing domain" unless $domain;
    my $offer = "START";

    my $filter            = Webservice::OVH::Helper->construct_filter( "domain" => $domain, "offer" => $offer );
    my $api               = $self->{_api_wrapper};
    my $response_duration = $api->rawCall( method => 'get', path => "/order/hosting/web/new$filter", noSignature => 0 );
    croak $response_duration->error if $response_duration->error;
    my $duration = $response_duration->content->[0];

    my $filter2 = Webservice::OVH::Helper->construct_filter( "domain" => $domain, "offer" => $offer );
    my $response = $api->rawCall( method => 'get', path => sprintf( "/order/hosting/web/new/%s%s", $duration, $filter2 ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 activate_free_email

Generates an order and pays the order for free webhosting.

=over

=item * Parameter: $domain - target domain for free webhosting, $params - zusätzliche Parameter beim hosting erlauben

=item * Return: L<Webservice::Me::Order>

=item * Synopsis: my $order = Webservice::OVH::Order::Hosting::Web->activate_free_email('mydomain.de');

=back

=cut

sub activate_free_email {

    my ( $self, $domain, $params ) = @_;

    my $module = $self->{_module};

    croak "Missing domain" unless $domain;
    my $offer    = 'START';
    my $dns_zone = 'NO_CHANGE';

    my $filter            = Webservice::OVH::Helper->construct_filter( "domain" => $domain, "offer" => $offer );
    my $api               = $self->{_api_wrapper};
    my $response_duration = $api->rawCall( method => 'get', path => sprintf( "/order/hosting/web/new%s", $filter ), noSignature => 0 );
    croak $response_duration->error if $response_duration->error;
    my $duration = $response_duration->content->[0];

    my $body = { domain => $domain, offer => 'START', dnsZone => $dns_zone, %$params };
    my $response = $api->rawCall( method => 'post', path => "/order/hosting/web/new/$duration", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $order = $module->me->order( $response->content->{orderId} );

    $order->pay_with_registered_payment_mean('fidelityAccount');

    return $order;
}

1;
