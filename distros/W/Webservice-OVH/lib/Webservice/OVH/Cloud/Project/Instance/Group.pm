package Webservice::OVH::Cloud::Project::Instance::Group;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Instance::Group

=head1 SYNOPSIS

    use Webservice::OVH;

    my $ovh = Webservice::OVH->new_from_json("credentials.json");

    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];

    my $groups = $project->instance->groups;
    
    foreach my $group (@$groups) {
        
        print $group->name;
    }

=head1 DESCRIPTION

Provides Instance object methods and id less methods for groups.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

=head2 _new_existing

Internal Method to create the Network object.
This method is not ment to be called directly.
This method can be reached by using the bridge object instance in project.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Instance::Group>

=item * Synopsis: Webservice::OVH::Cloud::Project::Instance::Group->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing project" unless $params{project};

    my $group_id    = $params{id};
    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $project     = $params{project};
    my $project_id  = $project->id;

    my $response = $api_wrapper->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/group/$group_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $group_id, _properties => $porperties, _project => $project }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new

Internal Method to create the Network object.
This method is not ment to be called directly.
This method can be reached by using the bridge object instance in project.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Instance::Group>

=item * Synopsis: Webservice::OVH::Cloud::Project::Instance::Group->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing project" unless $params{project};

    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $project     = $params{project};
    my $project_id  = $project->id;

    my @keys_needed = qw{ region name };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $body = { region => $params{region}, name => $params{name} };
    my $response = $api_wrapper->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/group", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $group_id   = $response->content->{id};
    my $properties = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $group_id, _properties => $properties, _project => $project }, $class;

    return $self;
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $group->project;

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

=item * Synopsis: print "Valid" if $group->is_valid;

=back

=cut

sub is_valid {

    my ($self) = @_;

    return $self->{_valid};
}

=head2 _is_valid

Internal method to check validity.
Difference is that this method carps an error.

=over

=item * Return: VALUE

=item * Synopsis: $group->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    carp "Group is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $group->id;

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

=item * Synopsis: my $properties = $group->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $group_id   = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/group/$group_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $name = $group->name;

=back

=cut

sub name {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{name};
}

=head2 region

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $region = $group->region;

=back

=cut

sub region {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{region};
}

=head2 instance_ids

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $instance_ids = $group->instance_ids;

=back

=cut

sub instance_ids {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{instance_ids};
}

=head2 affinity

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $affinity = $group->affinity;

=back

=cut

sub affinity {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{Affinity};
}

=head2 delete

Deletes the object api sided and sets it invalid.

=over

=item * Synopsis: $group->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $group_id   = $self->id;

    my $response = $api->rawCall( method => 'delete', path => "/cloud/project/$project_id/instance/group/$group_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

1;
