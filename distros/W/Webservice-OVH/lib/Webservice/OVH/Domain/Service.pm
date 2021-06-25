package Webservice::OVH::Domain::Service;

=encoding utf-8

=head1 NAME

Webservice::OVH::Domain::Service

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $service = $ovh->domain->service("mydomain.org");
    
    my $info = $service->service_info;
    my $last_update = $service->last_update;

=head1 DESCRIPTION

Provieds basic functionality for Services
A service contact_change can be initialized.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use DateTime;
use JSON;

our $VERSION = 0.46;

use Webservice::OVH::Helper;
use Webservice::OVH::Me::Contact;

=head2 _new

Internal Method to create the service object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Domain::Zone>

=item * Synopsis: Webservice::OVH::Domain::Zone->_new($ovh_api_wrapper, $zone_name, $module);

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

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _name => $service_name, _owner => undef, _service_info => undef, _properties => undef }, $class;

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
    my $response_service_info = $api->rawCall( method => 'get', path => "/domain/$service_name/serviceInfos", noSignature => 0 );

    croak $response_service_info->error if $response_service_info->error;

    $self->{_service_info} = $response_service_info->content;

    return $self->{_service_info};
}

=head2 properties

Retrieves properties of the service.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $service->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api                 = $self->{_api_wrapper};
    my $service_name        = $self->name;
    my $response_properties = $api->rawCall( method => 'get', path => "/domain/$service_name", noSignature => 0 );

    croak $response_properties->error if $response_properties->error;

    $self->{_properties} = $response_properties->content;

    return $self->{_properties};
}

=head2 dnssec_supported

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $dnssec_supported = $service->dnssec_supported;

=back

=cut

sub dnssec_supported {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{dnssecSupported} ? 1 : 0;
}

=head2 domain

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $domain = $service->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{domain};
}

=head2 glue_record_ipv6_supported

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $glue_record_ipv6_supported = $service->glue_record_ipv6_supported;

=back

=cut

sub glue_record_ipv6_supported {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{glueRecordIpv6Supported} ? 1 : 0;
}

=head2 glue_record_multi_ip_supported

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $glue_record_multi_ip_supported = $service->glue_record_multi_ip_supported;

=back

=cut

sub glue_record_multi_ip_supported {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{glueRecordMultiIpSupported} ? 1 : 0;
}

=head2 last_update

Exposed Property Value. Readonly.

=over

=item * Return: DateTime

=item * Synopsis: my $last_update = $service->last_update;

=back

=cut

sub last_update {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    my $str_datetime = $self->{_properties}->{lastUpdate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 last_update

Exposed Property Value. Readonly.

=over

=item * Return: DateTime

=item * Synopsis: my $last_update = $service->last_update;

=back

=cut

sub expiration {

    my ($self) = @_;

    $self->service_infos unless $self->{_service_info};

    my $str_datetime = $self->{_service_info}->{expiration};
    my $datetime     = Webservice::OVH::Helper->parse_date($str_datetime);
    return $datetime;
}

=head2 name_server_type

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $name_server_type = $service->name_server_type;

=back

=cut

sub name_server_type {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{nameServerType};
}

=head2 offer

Exposed Property Value. Readonly.

=over

=item * Return: HASH

=item * Synopsis: my $offer = $service->offer;

=back

=cut

sub offer {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{offer};
}

=head2 owo_supported

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $owo_supported = $service->owo_supported;

=back

=cut

sub owo_supported {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{owoSupported} ? 1 : 0;
}

=head2 parent_service

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $parent_service = $service->parent_service;

=back

=cut

sub parent_service {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{parentService};
}

=head2 transfer_lock_status

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $transfer_lock_status = $service->transfer_lock_status;

=back

=cut

sub transfer_lock_status {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{transferLockStatus};
}

=head2 whois_owner

Exposed Property Value. Readonly.

=over

=item * Return: L<Webservice::Me::Contact>

=item * Synopsis: my $owner = $service->whois_owner;

=back

=cut

sub whois_owner {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $properties = $self->{_properties} || $self->properties;
    my $owner_id   = $properties->{whoisOwner};
    my $owner      = $self->{_owner} = $self->{_owner} || Webservice::OVH::Me::Contact->_new_existing( wrapper => $api, id => $owner_id, module => $self->{_module} );

    return $self->{_owner};
}

=head2 change_contact

Initializes a change_contact procedure.
This generates a task. An email is sent to the other account-

=over

=item * Parameter: %params - key => value contact_billing contact_admin contact_tech - ovh account names

=item * Return: L<Webservice::Me::Task>

=item * Synopsis: $service->change_contact(contact_tech => 'otheraccount-ovh');

=back

=cut

sub change_contact {

    my ( $self, %params ) = @_;

    croak "at least one parameter needed: contact_billing contact_admin contact_tech" unless %params;

    my $api          = $self->{_api_wrapper};
    my $service_name = $self->name;
    my $body         = {};
    $body->{contactBilling} = $params{contact_billing} if exists $params{contact_billing};
    $body->{contactAdmin}   = $params{contact_admin}   if exists $params{contact_admin};
    $body->{contactTech}    = $params{contact_tech}    if exists $params{contact_tech};
    my $response = $api->rawCall( method => 'post', path => "/domain/$service_name/changeContact", body => $body, noSignature => 0 );

    croak $response->error if $response->error;

    my $tasks    = [];
    my $task_ids = $response->content;
    foreach my $task_id (@$task_ids) {

        my $task = $api->me->task_contact_change($task_id);
        push @$tasks, $task;
    }

    return $tasks;
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

    my $response = $api->rawCall( method => 'put', body => $body, path => "/domain/$service_name/serviceInfos", noSignature => 0 );
    croak $response->error if $response->error;

}

1;
