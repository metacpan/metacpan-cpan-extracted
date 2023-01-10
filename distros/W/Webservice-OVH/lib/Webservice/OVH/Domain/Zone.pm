package Webservice::OVH::Domain::Zone;

=encoding utf-8

=head1 NAME

Webservice::OVH::Domain::Zone

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $zone = $ovh->domain->zone("myzone.de");
    
    my $a_record = $zone->new_record(field_type => 'A', target => '0.0.0.0', ttl => 1000 );
    my $mx_record = $zone->new_record(field_type => 'MX', target => '1 my.mail.server.de.');
    
    my $records = $zone->records(filed_type => 'A', sub_domain => 'www');
    
    foreach my $record (@$records) {
    
        $record->change( target => '0.0.0.0' );
    }
    
    $zone->refresh;
    $zone->reset;
    
    $zone->change_contact(contact_billing => 'account-ovh', contact_tech => 'account-ovh', contact_admin => 'account-ovh');

=head1 DESCRIPTION

Provieds basic functionality for Zones. Records can be created and fetched.
Records can be fetched through a filter.
A zone contact_change can be initialized.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

use Webservice::OVH::Helper;
use Webservice::OVH::Domain::Zone::Record;

=head2 _new

Internal Method to create the zone object.
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

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $zone_name   = $params{id};

    croak "Missing zone_name" unless $zone_name;

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _name => $zone_name, _service_info => undef, _properties => undef, _records => {} }, $class;

    return $self;
}

=head2 service_infos

Retrieves additional infos about the zone. 
Infos that are not part of the properties

=over

=item * Return: HASH

=item * Synopsis: my $info = $zone->service_info;

=back

=cut

sub service_infos {

    my ($self) = @_;

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;
    my $response  = $api->rawCall( method => 'get', path => "/domain/zone/$zone_name/serviceInfos", noSignature => 0 );

    croak $response->error if $response->error;

    $self->{_service_info} = $response->content;

    return $self->{_service_info};
}

=head2 properties

Retrieves properties of the zone.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $zone->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;
    my $response  = $api->rawCall( method => 'get', path => "/domain/zone/$zone_name", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;

    return $self->{_properties};
}

=head2 dnssec_supported

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $value = $zone->dnssec_supported;

=back

=cut

sub dnssec_supported {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{dnssecSupported} ? 1 : 0;
}

=head2 has_dns_anycast

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $value = $zone->has_dns_anycast;

=back

=cut

sub has_dns_anycast {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{hasDnsAnycast} ? 1 : 0;
}

=head2 last_update

Exposed Property Value. Readonly.

=over

=item * Return: DateTime

=item * Synopsis: my $value = $zone->last_update;

=back

=cut

sub last_update {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    my $str_datetime = $self->{_properties}->{lastUpdate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 name_servers

Exposed Property Value. Readonly.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $value = $zone->name_servers;

=back

=cut

sub name_servers {

    my ($self) = @_;

    $self->properties unless $self->{_properties};

    return $self->{_properties}->{nameServers};
}

=head2 records

Produces an Array of record Objects. 
Can be filtered by field_type and sub_domain.

=over

=item * Parameter: %filter - (optional) - field_type => record type sub_domain => subdomain string

=item * Return: L<ARRAY>

=item * Synopsis: my $records = $zone->records(field_type => 'A', sub_domain => 'www');

=back

=cut

sub records {

    my ( $self, %filter ) = @_;

    my $filter_type      = ( exists $filter{field_type} && !$filter{field_type} ) ? "_empty_" : $filter{field_type};
    my $filter_subdomain = ( exists $filter{subdomain}  && !$filter{subdomain} )  ? "_empty_" : $filter{subdomain};
    my $filter = Webservice::OVH::Helper->construct_filter( "fieldType" => $filter_type, "subDomain" => $filter_subdomain );

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;
    my $response  = $api->rawCall( method => 'get', path => sprintf( "/domain/zone/$zone_name/record%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $record_ids = $response->content;
    my $records    = [];

    foreach my $record_id (@$record_ids) {

        my $record = $self->{_records}{$record_id} = $self->{_records}{$record_id} || Webservice::OVH::Domain::Zone::Record->_new_existing( wrapper => $api, module => $self->{_module}, zone => $self, id => $record_id );
        push @$records, $record;
    }

    return $records;
}

=head2 record

Returns a single record by id

=over

=item * Parameter: $record_id - id

=item * Return: L<Webservice::OVH::Domain::Zone::Record>

=item * Synopsis: my $record = $ovh->domain->zone->record(123456);

=back

=cut

sub record {

    my ( $self, $record_id ) = @_;

    croak "Missing record_id" unless $record_id;

    my $api               = $self->{_api_wrapper};
    my $from_array_record = $self->{_records}{$record_id} if $self->{_records}{$record_id} && $self->{_records}{$record_id}->is_valid;
    my $record            = $self->{_records}{$record_id} = $from_array_record || Webservice::OVH::Domain::Zone::Record->_new_existing( wrapper => $api, module => $self->{_module}, zone => $self, id => $record_id );

    return $record;
}

=head2 new_record

Creates a new record.

=over

=item * Parameter:  %params - refresh => 'true', 'false' - directly refreshes the zone target (required) => '0.0.0.0' ttl (optional) => 3000 sub_domain (optional) => 'www' field_type (required) => 'A'

=item * Return: L<Webservice::OVH::Domain::Zone::Record>

=item * Synopsis: my $record = $zone->new_record(field_type => 'MX', target => '1 my.mailserver.de.');

=back

=cut

sub new_record {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $record = Webservice::OVH::Domain::Zone::Record->_new( wrapper => $api, module => $self->{_module}, zone => $self, %params );

    return $record;
}

=head2 name

Name is the unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $name = $zone->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 change_contact

Changes contact information for this zone.
Contact must be another ovh account name.

=over

=item * Parameter: %params - contactBilling (optional) => 'account-ovh' contact_admin (optional) => 'account-ovh' contact_tech (optional)  => 'account-ovh'

=item * Return: L<Webservice::OVH::Me::Task>

=item * Synopsis: my $task = $zone->change_contact(contact_billing => 'another-ovh');

=back

=cut

sub change_contact {

    my ( $self, %params ) = @_;
    croak "at least one parameter needed: contact_billing contact_admin contact_tech" unless %params;

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;
    my $body      = {};
    $body->{contactBilling} = $params{contact_billing} if exists $params{contact_billing};
    $body->{contactAdmin}   = $params{contact_admin}   if exists $params{contact_admin};
    $body->{contactTech}    = $params{contact_tech}    if exists $params{contact_tech};
    my $response = $api->rawCall( method => 'post', path => "/domain/zone/$zone_name/changeContact", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $tasks    = [];
    my $task_ids = $response->content;
    foreach my $task_id (@$task_ids) {

        my $task = $api->me->task_contact_change($task_id);
        push @$tasks, $task;
    }

    return $tasks;
}

=head2 refresh

Refreshes the domain zone and applies changes.

=over

=item * Synopsis:$zone->refresh;

=back

=cut

sub refresh {

    my ($self)    = @_;
    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;

    my $response = $api->rawCall( method => 'post', path => "/domain/zone/$zone_name/refresh", body => {}, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 reset

Deletes all custom records and resetzt to default.

=over

=item * Parameter: $minimal - only creates nesseccary dns records 

=item * Synopsis: $zone->reset;

=back

=cut

sub reset {

    my ( $self, $minimal ) = @_;

    $minimal ||= 'false';

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->name;

    my $response = $api->rawCall( method => 'post', path => "/domain/zone/$zone_name/reset", body => {}, noSignature => 0 );
    croak $response->error if $response->error;
}

1;
