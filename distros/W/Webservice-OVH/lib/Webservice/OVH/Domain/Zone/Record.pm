package Webservice::OVH::Domain::Zone::Record;

=encoding utf-8

=head1 NAME

Webservice::OVH::Domain::Zone::Record

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $zone = $ovh->domain->zone("myzone.de");
    
    my $a_record = $zone->new_record(field_type => 'A', target => '0.0.0.0', ttl => 1000 );
    my $mx_record = $zone->new_record(field_type => 'MX', target => '1 my.mail.server.de.');
    
    my $records = $zone->records(filed_type => 'A', sub_domain => 'www');
    
    foreach my $record (@$records) {
    
        $record->change( target => '0.0.0.0' );
        $record->zone->refresh;
        $record->change( sub_domain => 'www', refresh => 'true' );
    }
    
    $record->delete('true');
    
    print "Not Valid anymore" unless $record->is_valid;

=head1 DESCRIPTION

Provides all api Record Methods available in the api.
Delete deletes the record object in the api and makes the object invalid.
No actions be done with it, when it is invalid.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

use Webservice::OVH::Me::Contact;

=head2 _new_existing

Internal Method to create a Record object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $zone - parent zone Objekt, $record_id => api intern id

=item * Return: L<Webservice::OVH::Domain::Zone::Record>

=item * Synopsis: Webservice::OVH::Domain::Zone::Record->_new_existing($ovh_api_wrapper, $module, $zone, $record_id);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing zone"    unless $params{zone};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $record_id   = $params{id};
    my $zone        = $params{zone};

    my $zone_name = $zone->name;
    my $response = $api_wrapper->rawCall( method => 'get', path => "/domain/zone/$zone_name/record/$record_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $record_id, _properties => $porperties, _zone => $zone }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new

Internal Method to create the zone object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $zone - parent zone, %params - key => value

=item * Return: L<Webservice::OVH::Domain::Zone::Record>

=item * Synopsis: Webservice::OVH::Domain::Zone::Record->_new($ovh_api_wrapper, $module, $zone_name, target => '0.0.0.0', field_type => 'A', sub_domain => 'www');

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing zone"    unless $params{zone};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $zone        = $params{zone};

    my @keys_needed = qw{ field_type target };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $zone_name = $zone->name;
    my $body      = {};
    $body->{subDomain} = $params{sub_domain} if exists $params{sub_domain};
    $body->{target}    = $params{target};
    $body->{ttl}       = $params{ttl} if exists $params{ttl};
    $body->{fieldType} = $params{field_type} if exists $params{field_type};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/domain/zone/$zone_name/record", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $record_id  = $response->content->{id};
    my $properties = $response->content;

    my $refresh = $params{'refresh'} || 'false';
    $zone->refresh if $refresh eq 'true';

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $record_id, _properties => $properties, _zone => $zone }, $class;

    return $self;
}

=head2 is_valid

When this record is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $record->is_valid;

=back

=cut

sub is_valid {

    my ($self) = @_;

    return $self->{_valid};
}

=head2 _is_valid

Intern method to check validity.
Difference is that this method carps an error.

=over

=item * Return: VALUE

=item * Synopsis: $record->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    my $record_id = $self->id;
    carp "Record $record_id is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 id

Returns the api id of this record 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $record->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 zone

Returns the zone this record is attached to. 

=over

=item * Return: L<Webservice::Domain::Zone>

=item * Synopsis: my $zone = $record->zone;

=back

=cut

sub zone {

    my ($self) = @_;

    return $self->{_zone};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $record->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->zone->name;
    my $record_id = $self->id;
    my $response  = $api->rawCall( method => 'get', path => "/domain/zone/$zone_name/record/$record_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 field_type

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $field_type = $record->field_type;

=back

=cut

sub field_type {

    my ($self) = @_;

    return $self->{_properties}->{fieldType};
}

=head2 sub_domain

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $sub_domain = $record->sub_domain;

=back

=cut

sub sub_domain {

    my ($self) = @_;

    return $self->{_properties}->{subDomain};
}

=head2 target

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $target = $record->target;

=back

=cut

sub target {

    my ($self) = @_;

    return $self->{_properties}->{target};
}

=head2 ttl

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $ttl = $record->ttl;

=back

=cut

sub ttl {

    my ($self) = @_;

    return $self->{_properties}->{ttl};
}

=head2 delete

Deletes the record api sided and sets this object invalid.
After deleting, the zone must be refreshed, if the refresh parameter is not set.

=over

=item * Parameter: $refresh 'true' 'false' undef - imidiate refreshing of the domain zone

=item * Synopsis: $record->delete('true');

=back

=cut

sub delete {

    my ( $self, $refresh ) = @_;

    return unless $self->_is_valid;

    my $api       = $self->{_api_wrapper};
    my $zone_name = $self->{_zone}->name;
    my $record_id = $self->id;
    my $response  = $api->rawCall( method => 'delete', path => "/domain/zone/$zone_name/record/$record_id", noSignature => 0 );
    croak $response->error if $response->error;

    $refresh ||= 'false';
    $self->zone->refresh if $refresh eq 'true';
    $self->{_valid} = 0;
}

=head2 change

Changes the record
After changing the zone must be refreshed, if the refresh parameter is not set.

=over

=item * Parameter: %params - key => value sub_domain target ttl refresh

=item * Synopsis: $record->change(sub_domain => 'www', refresh => 'true');

=back

=cut

sub change {

    my ( $self, %params ) = @_;

    return unless $self->_is_valid;

    if ( scalar keys %params != 0 ) {

        my $api       = $self->{_api_wrapper};
        my $zone_name = $self->{_zone}->name;
        my $record_id = $self->id;
        my $body      = {};
        $body->{subDomain} = $params{sub_domain} if exists $params{sub_domain};
        $body->{target}    = $params{target}     if exists $params{target};
        $body->{ttl}       = $params{ttl}        if exists $params{ttl};
        my $response = $api->rawCall( method => 'put', path => "/domain/zone/$zone_name/record/$record_id", body => $body, noSignature => 0 );
        croak $response->error if $response->error;

        my $refresh = $params{refresh} || 'false';
        $self->zone->refresh if $refresh eq 'true';
        $self->properties;
    }
}

1;
