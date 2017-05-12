package Webservice::OVH::Order::Hosting;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Hosting

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $info = $ovh->hosting->web->free_email_info;

=head1 DESCRIPTION

Only Helper Object to Web Api Sub-Object.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.3;

use Webservice::OVH::Order::Hosting::Web;

=head2 _new

Internal Method to create the Hosting object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $type - intern type

=item * Return: L<Webservice::OVH::Me::Task>

=item * Synopsis: Webservice::OVH::Me::Task->_new($ovh_api_wrapper, $type, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $web = Webservice::OVH::Order::Hosting::Web->_new( wrapper => $api_wrapper, module => $module );

    my $self = bless { _api_wrapper => $api_wrapper, _web => $web }, $class;

    return $self;
}

=head2 web

Gives acces to the /order/hosting/web methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Hosting::Web>

=item * Synopsis: $ovh->order->hosting->web

=back

=cut

sub web {

    my ($self) = @_;

    return $self->{_web};
}

1;
