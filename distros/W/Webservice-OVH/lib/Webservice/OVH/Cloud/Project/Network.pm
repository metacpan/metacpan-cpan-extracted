package Webservice::OVH::Cloud::Project::Network;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Network

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $networks = $project->network->privates;
    
    foreach my $network (@$networks) {
        
        print @$networks->status;
    }

=head1 DESCRIPTION

Bridge Object to private and in future public networks.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.47;

use Webservice::OVH::Cloud::Project::Network::Private;

=head2 _new_existing

Internal Method to create the Network object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::SSH>

=item * Synopsis: Webservice::OVH::Cloud::Project::SSH->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing project" unless $params{project};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $self = bless { _project => $params{project}, _module => $params{module}, _api_wrapper => $params{wrapper}, _private => {}, _available_private => [] }, $class;

    return $self;
}

=head2 project

Shorthand to call $self->project directly for internal usage.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $project->network->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_project};
}

=head2 private_exists

Returns 1 if object is available for the connected account, 0 if not.

=over

=item * Parameter: $network_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "network exists" if $project->network->private_exists($id);

=back

=cut

sub private_exists {

    my ( $self, $network_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->project->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/network/private", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;
        my @net_ids = grep { $_ = $_->{id} } @$list;

        return ( grep { $_ eq $network_id } @net_ids ) ? 1 : 0;

    } else {

        my $list = $self->{_available_private};

        return ( grep { $_ eq $network_id } @$list ) ? 1 : 0;
    }
}

=head2 privates

Produces an array of all available private networks that are connected to the project.

=over

=item * Return: ARRAY

=item * Synopsis: my $private_networks = $project->privates;

=back

=cut

sub privates {

    my ( $self, %filter ) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/network/private", noSignature => 0 );
    croak $response->error if $response->error;

    my $private_array = $response->content;
    my $privates      = [];
    my @net_ids       = grep { $_ = $_->{id} } @$private_array;
    $self->{_available_private} = \@net_ids;

    foreach my $network_id (@net_ids) {

        if ( $self->private_exists( $network_id, 1 ) ) {
            my $private = $self->{_private}{$network_id} = $self->{_private}{$network_id} || Webservice::OVH::Cloud::Project::Network::Private->_new_existing( wrapper => $api, module => $self->{_module}, project => $self->project, id => $network_id );
            push @$privates, $private;
        }
    }

    return $privates;
}

=head2 private

Returns a single object by id

=over

=item * Parameter: $network_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::Network::Private>

=item * Synopsis: my $private_network = $project->private($id);

=back

=cut

sub private {

    my ( $self, $network_id ) = @_;

    if ( $self->private_exists($network_id) ) {

        my $api = $self->{_api_wrapper};
        my $private = $self->{_private}{$network_id} = $self->{_private}{$network_id} || Webservice::OVH::Cloud::Project::Network::Private->_new_existing( wrapper => $api, module => $self->{_module}, project => $self->project, id => $network_id );

        return $private;
    } else {

        carp "Network $network_id doesn't exists";
        return undef;
    }
}

=head2 create_private

Creates a new network.

=over

=item * Parameter: %params - key => value (required) vlan_id name (optional) region

=item * Return: <Webservice::OVH::Cloud::Project::Network::Private>

=item * Synopsis: my $private_network = $project->create_private( vlan_id => 6, name => 'Test Network' );

=back

=cut

sub create_private {

    my ( $self, %params ) = @_;

    return Webservice::OVH::Cloud::Project::Network::Private->_new( module => $self->{_module}, wrapper => $self->{_api_wrapper}, project => $self->project, %params );
}

1;
