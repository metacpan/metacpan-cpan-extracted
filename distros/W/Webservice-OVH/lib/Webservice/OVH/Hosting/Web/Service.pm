package Webservice::OVH::Hosting::Web::Service;

=encoding utf-8

=head1 NAME

Webservice::OVH::Hosting::Web::Service

=head1 SYNOPSIS

=head1 DESCRIPTION

Provieds basic functionality for webhosting Services

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use DateTime;
use JSON;

our $VERSION = 0.47;

=head2 _new

Internal Method to create the service object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Hosting::Web::service>

=item * Synopsis: Webservice::OVH::Hosting::Web::service->_new($ovh_api_wrapper, $service_name, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};

    my $module       = $params{module};
    my $api_wrapper  = $params{wrapper};
    my $service_name = $params{id};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _name => $service_name, _service_info => undef, _properties => undef }, $class;

    return $self;
}

=head2 name

Name is the unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $name = $service->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 service_infos

Retrieves additional infos about the service. 
Infos that are not part of the properties

=over

=item * Return: HASH

=item * Synopsis: my $info = $service->service_info;

=back

=cut

sub service_infos {

    my ($self) = @_;

    my $api                   = $self->{_api_wrapper};
    my $service_name          = $self->name;
    my $response_service_info = $api->rawCall( method => 'get', path => "/hosting/web/$service_name/serviceInfos", noSignature => 0 );

    croak $response_service_info->error if $response_service_info->error;

    $self->{_service_info} = $response_service_info->content;

    return $self->{_service_info};
}

=head2 change_service_infos

Change service_infos let you change the autorenewal method for this service

=over

=item * Parameter: %params - key => value renew(required) => { automatic(required), delete_at_expiration(required), forced(required), period(required) }

=item * Synopsis: $service->change_service_infos(renew => {  automatic => 'yes', delete_at_expiration => 'yes', forced => 'yes', period => 12 });

=back

=cut

sub change_service_infos {

    my ( $self, %params ) = @_;

    croak "Missing parameter: renew" unless $params{renew};

    my @keys = qw{ automatic delete_at_expiration forced period };
    if ( my @missing_parameters = grep { not exists $params{renew}{$_} } @keys ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $options = {};
    $options->{automatic}          = $params{renew}{automatic} eq 'true'            || $params{renew}{automatic} eq 'yes'            || $params{renew}{automatic} eq '1'            ? JSON::true : JSON::false;
    $options->{deleteAtExpiration} = $params{renew}{delete_at_expiration} eq 'true' || $params{renew}{delete_at_expiration} eq 'yes' || $params{renew}{delete_at_expiration} eq '1' ? JSON::true : JSON::false;
    $options->{forced}             = $params{renew}{forced} eq 'true'               || $params{renew}{forced} eq 'yes'               || $params{renew}{forced} eq '1'               ? JSON::true : JSON::false;

    my $api          = $self->{_api_wrapper};
    my $service_name = $self->name;
    my $body         = {};
    $body->{renew}{period}             = $params{renew}{period};
    $body->{renew}{automatic}          = $options->{automatic};
    $body->{renew}{deleteAtExpiration} = $options->{deleteAtExpiration};
    $body->{renew}{forced}             = $options->{forced};

    my $response = $api->rawCall( method => 'put', body => $body, path => "/hosting/web/$service_name/serviceInfos", noSignature => 0 );
    croak $response->error if $response->error;

}

1