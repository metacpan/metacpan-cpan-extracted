package Webservice::OVH::Order::Email;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Email

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $available_email_domains = $ovh->order->email->domain->available_services;

=head1 DESCRIPTION

Only Helper Object to Web Api Sub-Object.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

use Webservice::OVH::Order::Email::Domain;

=head2 _new

Internal Method to create the Hosting object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order::Email>

=item * Synopsis: Webservice::OVH::Order::Email->_new($ovh_api_wrapper, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $domain = Webservice::OVH::Order::Email::Domain->_new( wrapper => $api_wrapper, module => $module );

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _domain => $domain }, $class;

    return $self;
}

=head2 domain

Gives acces to the /order/email/domain methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Email::Domain>

=item * Synopsis: $ovh->order->email->domain

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

1;
