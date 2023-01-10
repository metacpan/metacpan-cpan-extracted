package Webservice::OVH::Order::Email::Domain;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Email::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $available_services = $ovh->order->email->domain->available_services;

=head1 DESCRIPTION

Provides the possibility to order MX packaged. The api methods are deprecated, but no alternative is give at the moment.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

=head2 _new

Internal Method to create the Domain object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order::Email::Domain>

=item * Synopsis: Webservice::OVH::Order::Email::Domain->_new($ovh_api_wrapper, $module);

=back

=cut

sub _new {
    
    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    
    my $self = bless { _module => $module, _api_wrapper => $api_wrapper}, $class;

    return $self;
}

=head2 _new

Returns an array of available services. 

=over

=item * Return: L<ARRAY>

=item * Synopsis: Webservice::OVH::Order::Email::Domain->_new($ovh_api_wrapper, $module);

=back

=cut

sub available_services {
    
    my ($self) = @_;
    
    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/order/email/domain", noSignature => 0 );
    croak $response->error if $response->error;
    
    return $response->content;
}

=head2 allowed_durations

Returns an array of allowed durations. 
DEPRECATED

=over

=item * Parameter: $domain - target domain for MX package, $offer - MX offer

=item * Return: L<ARRAY>

=item * Synopsis: $ovh->order->email->domain->allowed_durations('mydomain.de', '100');

=back

=cut

sub allowed_durations {
    
    my ($self, $domain, $offer) = @_;
    
    croak "Missing offer" unless $offer;
    croak "Missing domain" unless $domain;
    
    my $filter = Webservice::OVH::Helper->construct_filter( "domain" => $domain, "offer" => $offer );
    
    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/order/email/domain/new$filter", noSignature => 0 );
    croak $response->error if $response->error;
    
    return $response->content;
}

=head2 allowed_durations

Returns information for a desired MX package.
DEPRECATED

=over

=item * Parameter: $domain - target domain for MX package, $offer - MX offer, $duration - allowed duration

=item * Return: L<ARRAY>

=item * Synopsis: $ovh->order->email->domain->info('mydomain.de', '100', $allowed_durations->[0]);

=back

=cut

sub info {
    
    my ($self, $domain, $offer, $duration) = @_;
    
    croak "Missing offer" unless $offer;
    croak "Missing duration" unless $duration;
    croak "Missing domain" unless $domain;
    
    my $filter = Webservice::OVH::Helper->construct_filter( "domain" => $domain, "offer" => $offer );
    
    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => sprintf("/order/email/domain/new/%s%s", $duration, $filter), noSignature => 0 );
    croak $response->error if $response->error;
    
    return $response->content;
}

=head2 new

Generates an order for the desired MX package.
DEPRECATED

=over

=item * Parameter: $domain - target domain for MX package, $offer - MX offer, $duration - allowed duration

=item * Return: L<ARRAY>

=item * Synopsis: $ovh->order->email->domain->new('mydomain.de', '100', $allowed_durations->[0]);

=back

=cut

sub new {
    
    my ($self, $domain, $offer, $duration) = @_;
    
    croak "Missing offer" unless $offer;
    croak "Missing duration" unless $duration;
    croak "Missing domain" unless $domain;
    
    my $api = $self->{_api_wrapper};
    my $module = $self->{_module};
    my $body = { offer => $offer, domain => $domain };
    my $response = $api->rawCall( method => 'post', path => "/order/email/domain/new/$duration", body => $body, noSignature => 0 );
    croak $response->error if $response->error;
    
    my $order = $module->me->order($response->content->{orderId});
    
    return $order;
}


1;