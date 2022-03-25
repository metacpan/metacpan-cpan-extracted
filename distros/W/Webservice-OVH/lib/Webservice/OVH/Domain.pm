package Webservice::OVH::Domain;

=encoding utf-8

=head1 NAME

Webservice::OVH::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $services = $ovh->domain->services;
    foreach my $service (@$services) {
        
        print $service->name;
    }
    
    my $ = $ovh->domain->zones;
    foreach my $zone (@$zones) {
        
        print $zone->name;
    }
    
    print "I have a zone" if $ovh->domain->zone_exists("myaddress.de");
    print "I have a service" if $ovh->domain->service_exists("myaddress.de");

=head1 DESCRIPTION

Gives access to services and zones connected to the uses account.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.47;

use Webservice::OVH::Domain::Service;
use Webservice::OVH::Domain::Zone;

=head2 _new

Internal Method to create the domain object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order>

=item * Synopsis: Webservice::OVH::Order->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _services => {}, _zones => {}, _aviable_services => [], _aviable_zones => [] }, $class;

    return $self;
}

=head2 service_exists

Returns 1 if service is available for the connected account, 0 if not.

=over

=item * Parameter: $service_name - Domain name, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "mydomain.com exists" if $ovh->domain->service_exists("mydomain.com");

=back

=cut

sub service_exists {

    my ( $self, $service_name, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api = $self->{_api_wrapper};
        my $response = $api->rawCall( method => 'get', path => "/domain", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        return ( grep { $_ eq $service_name } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_aviable_services};

        return ( grep { $_ eq $service_name } @$list ) ? 1 : 0;
    }
}

=head2 zone_exists

Returns 1 if zone is available for the connected account, 0 if not.

=over

=item * Parameter: $zone_name - Domain name, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "zone mydomain.com exists" if $ovh->domain->zone_exists("mydomain.com");

=back

=cut

sub zone_exists {

    my ( $self, $zone_name, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api = $self->{_api_wrapper};
        my $response = $api->rawCall( method => 'get', path => "/domain/zone", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        return ( grep { $_ eq $zone_name } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_aviable_zones};

        return ( grep { $_ eq $zone_name } @$list ) ? 1 : 0;
    }
}

=head2 services

Produces an array of all available services that are connected to the used account.

=over

=item * Return: ARRAY

=item * Synopsis: my $services = $ovh->order->services();

=back

=cut

sub services {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/domain", noSignature => 0 );
    croak $response->error if $response->error;

    my $service_array = $response->content;
    my $services      = [];
    $self->{_aviable_services} = $service_array;

    foreach my $service_name (@$service_array) {
        if ( $self->service_exists( $service_name, 1 ) ) {
            my $service = $self->{_services}{$service_name} = $self->{_services}{$service_name} || Webservice::OVH::Domain::Service->_new( wrapper => $api, id => $service_name, module => $self->{_module} );
            push @$services, $service;
        }
    }

    return $services;
}

=head2 zones

Produces an array of all available zones that are connected to the used account.

=over

=item * Return: ARRAY

=item * Synopsis: my $zones = $ovh->order->zones();

=back

=cut

sub zones {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/domain/zone", noSignature => 0 );
    croak $response->error if $response->error;

    my $zone_names = $response->content;
    my $zones      = [];
    $self->{_aviable_zones} = $zone_names;

    foreach my $zone_name (@$zone_names) {

        if ( $self->zone_exists( $zone_name, 1 ) ) {
            my $zone = $self->{_zones}{$zone_name} = $self->{_zones}{$zone_name} || Webservice::OVH::Domain::Zone->_new( wrapper => $api, id => $zone_name, module => $self->{_module} );
            push @$zones, $zone;
        }
    }

    return $zones;
}

=head2 service

Returns a single service by name

=over

=item * Parameter: $service_name - domain name

=item * Return: L<Webservice::OVH::Domain::Service>

=item * Synopsis: my $service = $ovh->domain->service("mydomain.com");

=back

=cut

sub service {

    my ( $self, $service_name ) = @_;

    if ( $self->service_exists($service_name) ) {

        my $api = $self->{_api_wrapper};
        my $service = $self->{_services}{$service_name} = $self->{_services}{$service_name} || Webservice::OVH::Domain::Service->_new( wrapper => $api, id => $service_name, module => $self->{_module} );

        return $service;
    } else {

        carp "Service $service_name doesn't exists";
        return undef;
    }
}

=head2 zone

Returns a single zone by name

=over

=item * Parameter: $zone_name - domain name

=item * Return: L<Webservice::OVH::Domain::Zone>

=item * Synopsis: my $zone = $ovh->domain->zone("mydomain.com");

=back

=cut

sub zone {

    my ( $self, $zone_name ) = @_;

    if ( $self->zone_exists($zone_name) ) {
        my $api = $self->{_api_wrapper};
        my $zone = $self->{_zones}{$zone_name} = $self->{_zones}{$zone_name} || Webservice::OVH::Domain::Zone->_new( wrapper => $api, id => $zone_name, module => $self->{_module} );

        return $zone;

    } else {

        carp "Zone $zone_name doesn't exists";
        return undef;
    }

}

1;
