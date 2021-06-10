package Webservice::OVH::Cloud::Project::Network::Private::Subnet;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Network::Private::Subnet

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $networks = $example_project->network->privates;
    
    foreach my $network (@$networks) {
        
        my $subnets = $network->subnets;
        
        foreach my $subnet (@$subnets) {
            
            print $subnet->name;
        }
    }

=head1 DESCRIPTION

Gives access to subnet methods.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use JSON;

our $VERSION = 0.43;

=head2 _new_existing

Internal Method to create the Subnet object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private::Subnet>

=item * Synopsis: Webservice::OVH::Cloud::Project::Network::Private::Subnet->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing project" unless $params{project};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing module"  unless $params{module};

    # Special Case, because subnet properties can't be called individually
    my $project_id = $params{project}->id;
    my $properties = $params{properties};
    my $api        = $params{wrapper};
    my $module     = $params{module};
    my $subnet_id  = $properties->{id};
    my $private    = $params{private};

    # No api check possible, because single subnets can't be checked
    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api, _id => $subnet_id, _properties => $properties, _project => $params{project}, _network => $private }, $class;

    return $self;
}

=head2 _new_existing

Internal Method to create the Subnet object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private::Subnet>

=item * Synopsis: Webservice::OVH::Cloud::Project::Network::Private::Subnet->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{project};
    die "Missing project" unless $params{wrapper};
    die "Missing wrapper" unless $params{module};
    die "Missing module"  unless $params{private};

    my $dhcp       = $params{dhcp}      && ( $params{dhcp} eq 'true'       || $params{dhcp} eq '1'       || $params{dhcp} eq 'yes' )       ? JSON::true : JSON::false;
    my $no_gateway = $params{noGateway} && ( $params{no_gateway} eq 'true' || $params{no_gateway} eq '1' || $params{no_gateway} eq 'yes' ) ? JSON::true : JSON::false;

    my $project_id = $params{project}->id;
    my $api        = $params{wrapper};
    my $module     = $params{module};
    my $private    = $params{private};

    my @keys_needed = qw{ network end region start };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $network_id = $private->id;

    my $body = {};
    $body->{dhcp}      = $dhcp;
    $body->{end}       = $params{end};
    $body->{network}   = $params{network};
    $body->{noGateway} = $no_gateway;
    $body->{region}    = $params{region};
    $body->{start}     = $params{start};

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/network/private/$network_id/subnet", body => $body, noSignature => 0 );
    die $response->error if $response->error;

    my $subnet_id  = $response->content->{id};
    my $properties = $response->content;

    my $self = bless { _network => $private, _module => $module, _valid => 1, _api_wrapper => $api, _id => $subnet_id, _properties => $properties, _project => $params{project} }, $class;

    return $self;
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $subnet->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_project};
}

=head2 project

Root Network.

=over

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private>

=item * Synopsis: my $project = $subnet->project;

=back

=cut

sub network {

    my ($self) = @_;

    return $self->{_network};
}

=head2 is_valid

When this object is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $subnet->is_valid;

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

=item * Synopsis: $subnet->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    carp "Subnet is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $subnet->id;

=back

=cut

sub id {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_id};
}

=head2 gateway_ip

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $gateway_ip = $subnet->gateway_ip;

=back

=cut

sub gateway_ip {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{gatewayIp};
}

=head2 cidr

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $cidr = $subnet->cidr;

=back

=cut

sub cidr {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{cidr};
}

=head2 ip_pools

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $ip_pools = $subnet->ip_pools;

=back

=cut

sub ip_pools {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{ipPools};
}

=head2 delete

Deletes the object api sided and sets it invalid.

=over

=item * Synopsis: $subnet->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $network_id = $self->network->id;
    my $subnet_id  = $self->id;
    my $response   = $api->rawCall( method => 'delete', path => "/cloud/project/$project_id/network/private/$network_id/subnet/$subnet_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

1;
