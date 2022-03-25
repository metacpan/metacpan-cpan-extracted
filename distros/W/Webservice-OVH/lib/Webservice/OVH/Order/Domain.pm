package Webservice::OVH::Order::Domain;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $available_domains = $ovh->order->domain->zone->existing;

=head1 DESCRIPTION

Only Helper Object to Web Api Sub-Object.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.47;

use Webservice::OVH::Order::Domain::Zone;

=head2 _new

Internal Method to create the Domain object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order::Domain>

=item * Synopsis: Webservice::OVH::Order::Domain->_new($ovh_api_wrapper, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $zone = Webservice::OVH::Order::Domain::Zone->_new( wrapper => $api_wrapper, module => $module );

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _zone => $zone }, $class;

    return $self;
}

=head2 zone

Gives acces to the /order/domain/zone methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Domain::Zone>

=item * Synopsis: $ovh->order->domain->zone

=back

=cut

sub zone {

    my ($self) = @_;

    return $self->{_zone};
}

1;
