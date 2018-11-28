package Webservice::OVH::Order::Domain::Zone;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Domain::Zone

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $existing_zones = $ovh->order->domain->zone->existing;

=head1 DESCRIPTION

Provides the possibility to order domain zones only.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

use Webservice::OVH::Me::Order;

=head2 _new

Internal Method to create the Zone object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order::Domain::Zone>

=item * Synopsis: Webservice::OVH::Order::Domain::Zone->_new($ovh_api_wrapper, $module);

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

=head2 _new

Returns an array with all available zones connected to the active account.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $existing_zones = $ovh->order->domain->zone->existing;

=back

=cut

sub existing {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};

    my $response = $api->rawCall( method => 'get', path => "/order/domain/zone", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 _new

Gets information about a requested zone order.

=over

=item * Return: HASH

=item * Synopsis: my $existing_zones = $ovh->order->domain->zone->existing;

=back

=cut

sub info_order {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};

    my $response = $api->rawCall( method => 'get', path => "/order/domain/zone/new", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 _new

Gets information about a requested zone order.

=over

=item * Parameter: $zone_name - desired zone, $minimized - only mandatory record entries 

=item * Return: L<Webservice::OVH::Me::Order>

=item * Synopsis: my $oder = $ovh->order->domain->zone->order('mydomain.de', 'true');

=back

=cut

sub order {

    my ( $self, $zone_name, $minimized ) = @_;
    
    $minimized ||= 'false';

    my $api = $self->{_api_wrapper};
    my $module = $self->{_module};

    my $response = $api->rawCall( method => 'post', path => "/order/domain/zone/new", body => { zoneName => $zone_name, minimized => $minimized }, noSignature => 0 );
    croak $response->error if $response->error;

    my $order = $module->me->order( $response->content->{orderId} );

    return $order;
}

=head2 _new

Gets available options for the desired zone order.

=over

=item * Parameter: $zone_name - desired zone 

=item * Return: HASH

=item * Synopsis: my $options = $ovh->order->domain->zone->options('mydomain.de');

=back

=cut

sub options {

    my ( $self, $zone_name ) = @_;

    my $api = $self->{_api_wrapper};

    my $response = $api->rawCall( method => 'get', path => "/order/domain/zone/$zone_name", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

1;
