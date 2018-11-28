package Webservice::OVH::Cloud::Project::IP::Failover;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::IP::Failover

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $failover_ips = $project->ip->failovers;
    
    foreach my $ip (@$failover_ips) {
        
        print $ip->routed_to;
    }

=head1 DESCRIPTION

Gives access to failover ip functionality.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

=head2 _new

Internal Method to create the SSH object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::IP::Failover>

=item * Synopsis: Webservice::OVH::Cloud::Project::IP::Failover->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing project" unless $params{project};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $project     = $params{project};
    my $failover_id = $params{id};

    my $self = bless { module => $module, _api_wrapper => $api_wrapper, _project => $project, _id => $failover_id, _properties => {} }, $class;

    $self->properties;

    return $self;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $failover_ip->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $failover_ip->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_propject};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $failover->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $failover_id = $self->id;
    my $project_id  = $self->project->id;
    my $response    = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/ip/failover/$failover_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 continent_code

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $continent_code = $failover_ip->continent_code;

=back

=cut

sub continent_code {

    my ($self) = @_;

    return $self->{_properties}->{continentCode};
}

=head2 progress

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $progress = $failover_ip->progress;

=back

=cut

sub progress {

    my ($self) = @_;

    return $self->{_properties}->{progress};
}

=head2 status

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $status = $failover_ip->status;

=back

=cut

sub status {

    my ($self) = @_;

    return $self->{_properties}->{status};
}

=head2 ip

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $ip = $failover_ip->ip;

=back

=cut

sub ip {

    my ($self) = @_;

    return $self->{_properties}->{ip};
}

=head2 routed_to

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $routed_to = $failover_ip->routed_to;

=back

=cut

sub routed_to {

    my ($self) = @_;

    return $self->{_properties}->{routedTo};
}

=head2 sub_type

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $sub_type = $failover_ip->sub_type;

=back

=cut

sub sub_type {

    my ($self) = @_;

    return $self->{_properties}->{subType};
}

=head2 block

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $block = $failover_ip->block;

=back

=cut

sub block {

    my ($self) = @_;

    return $self->{_properties}->{block};
}

=head2 geoloc

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $geoloc = $failover_ip->geoloc;

=back

=cut

sub geoloc {

    my ($self) = @_;

    return $self->{_properties}->{geoloc};
}

=head2 attach

Attach failover ip to an instance.

=over

=item * Parameter: instance_id - instance id

=item * Synopsis: $failover_ip->attach($instace_id);

=back

=cut

sub attach {

    my ( $self, $instance_id ) = @_;

    my $api         = $self->{_api_wrapper};
    my $failover_id = $self->id;
    my $project_id  = $self->project->id;

    croak "Missing instance_id" unless $instance_id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/ip/failover/$failover_id/attach", body => { instanceId => $instance_id }, noSignature => 0 );
    croak $response->error if $response->error;
}

1;
