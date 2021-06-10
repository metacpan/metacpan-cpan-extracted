package Webservice::OVH::Cloud::Project::Network::Private;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Network::Private

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $networks = $example_project->network->privates;
    
    foreach my $network (@$networks) {
        
        print $network->name;
    }

=head1 DESCRIPTION

Gives access Private Network methods.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.43;

use Webservice::OVH::Cloud::Project::Network::Private::Subnet;

=head2 _new_existing

Internal Method to create the Private object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private>

=item * Synopsis: Webservice::OVH::Cloud::Project::Network::Private->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing project" unless $params{project};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing module"  unless $params{module};

    my $project_id = $params{project}->id;
    my $network_id = $params{id};
    my $api        = $params{wrapper};
    my $module     = $params{module};
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/network/private/$network_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _available_subnets => [], _subnets => {}, _module => $module, _valid => 1, _api_wrapper => $api, _id => $network_id, _properties => $porperties, _project => $params{project} }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new_existing

Internal Method to create the Private object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private>

=item * Synopsis: Webservice::OVH::Cloud::Project::Network::Private->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    my $project_id = $params{project}->id;
    my $api        = $params{wrapper};
    my $module     = $params{module};

    my @keys_needed = qw{ project wrapper module vlan_id name };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $body = {};
    $body->{vlanId}  = $params{vlan_id};
    $body->{name}    = $params{name};
    $body->{regions} = $params{region} if exists $params{region};
    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/network/private", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $network_id = $response->content->{id};
    my $properties = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api, _id => $network_id, _properties => $properties, _project => $params{project} }, $class;

    return $self;
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $private_network->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_project};
}

=head2 is_valid

When this object is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $private_network->is_valid;

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

=item * Synopsis: $private_network->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    carp "Network is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $private_network->id;

=back

=cut

sub id {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_id};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $private_network->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/network/private/$network_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 regions

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $regions = $private_network->regions;

=back

=cut

sub regions {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{regions};
}

=head2 status

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $status = $private_network->status;

=back

=cut

sub status {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{status};
}

=head2 name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $name = $private_network->name;

=back

=cut

sub name {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{name};
}

=head2 type

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $type = $private_network->type;

=back

=cut

sub type {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{type};
}

=head2 vlan_id

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $vlan_id = $private_network->vlan_id;

=back

=cut

sub vlan_id {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{vlanId};
}

=head2 change

Changes the private network.

=over

=item * Parameter: $name - name to be changed

=item * Synopsis: $private_network->change(name => 'Test network');

=back

=cut

sub change {

    my ( $self, $name ) = @_;

    return unless $self->_is_valid;

    croak "Missing name" unless $name;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->id;

    my $response = $api->rawCall( method => 'put', path => "/cloud/project/$project_id/network/private/$network_id", body => { name => $name }, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;
}

=head2 delete

Deletes the object api sided and sets it invalid.

=over

=item * Synopsis: $private_network->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->id;

    my $response = $api->rawCall( method => 'delete', path => "/cloud/project/$project_id/network/private/$network_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

=head2 region

Activate private network in a new region

=over

=item * Parameter: $region - region name in which the network should be activated

=item * Synopsis: $private_network->region('GRA1');

=back

=cut

sub region {

    my ( $self, $region ) = @_;

    return unless $self->_is_valid;

    croak "Missing region" unless $region;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/network/private/$network_id/region", body => { region => $region }, noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 subnets

Produces an array of all available subnets.

=over

=item * Return: ARRAY

=item * Synopsis: my $subnets = $private_network->subnets;

=back

=cut

sub subnets {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/network/private/$network_id/subnet", noSignature => 0 );
    croak $response->error if $response->error;

    my $subnet_array = $response->content;
    my $subnets      = [];
    $self->{_available_subnets} = $subnet_array;

    foreach my $subnet (@$subnet_array) {

        my $subnet_id = $subnet->{id};
        my $subnet    = $self->{_subnets}{$subnet_id} =
          $self->{_subnets}{$subnet_id} || Webservice::OVH::Cloud::Project::Network::Private::Subnet->_new_existing( wrapper => $api, module => $self->{_module}, project => $self->project, id => $subnet_id, network => $self, properties => $subnet );
        push @$subnets, $subnet;
    }

    return $subnets;
}

=head2 subnet

Returns a single subnet by id

=over

=item * Parameter: $subnet_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private::Subnet>

=item * Synopsis: my $subnet = $private_network->subnet($id);

=back

=cut

sub subnet {

    my ( $self, $subnet_id ) = @_;

    my $subnets = $self->subnets;

    my @subnet_search = grep { $_->id eq $subnet_id } @$subnet_id;

    return scalar @subnet_search > 0 ? $subnet_search[0] : undef;
}

=head2 create_subnet

Create a new network subnet.

=over

=item * Parameter: %params - key => value (required) dhcp no_gateway end network region start

=item * Return: <Webservice::OVH::Cloud::Project::Network::Private::Subnet>

=item * Synopsis: my $subnet = $project->create_subnet( dhcp => 1, no_gateway => 1, end => "192.168.1.24", start => "192.168.1.12", network => "192.168.1.0/24", region => "GRA1" );

=back

=cut

sub create_subnet {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $subnet = Webservice::OVH::Cloud::Project::Network::Private::Subnet->_new( project => $self->project, wrapper => $api, module => $self->{_module}, private => $self, %params );

    return $subnet;
}

1;
