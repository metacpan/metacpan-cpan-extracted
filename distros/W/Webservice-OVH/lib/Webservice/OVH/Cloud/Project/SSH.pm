package Webservice::OVH::Cloud::Project::SSH;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::SSH

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $keys = $project->ssh_keys;
    
    foreach my $key (@$keys) {
        
        print $key->name;
        $key->delete;
    }

=head1 DESCRIPTION

Gives access to ssh key functionalty for a specific project.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

=head2 _new_existing

Internal Method to create the SSH object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::SSH>

=item * Synopsis: Webservice::OVH::Cloud::Project::SSH->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing project" unless $params{project};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $project     = $params{project};
    my $key_id      = $params{id};

    my $project_id = $project->id;
    my $response = $api_wrapper->rawCall( method => 'get', path => "/cloud/project/$project_id/sshkey/$key_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $key_id, _properties => $porperties, _project => $project }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new

Internal Method to create the SSH object.
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

    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $project     = $params{project};

    my @keys_needed = qw{ public_key name };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $project_id = $project->id;
    my $body       = {};
    $body->{name}      = $params{name};
    $body->{publicKey} = $params{public_key};
    $body->{region}    = $params{region} if exists $params{region};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/cloud/project/$project_id/sshkey", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $key_id = $response->content->{id};

    my $properties = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $key_id, _properties => $properties, _project => $project }, $class;

    return $self;
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $ssh_key->project;

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

=item * Synopsis: print "Valid" if $ssh_key->is_valid;

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

=item * Synopsis: $ssh_key->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    carp "Key is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $ssh_key->id;

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

=item * Synopsis: my $properties = $ssh_key->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $key_id     = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/sshkey/$key_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 finger_print

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $finger_print = $ssh_key->finger_print;

=back

=cut

sub finger_print {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{fingerPrint};
}

=head2 regions

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $regions = $ssh_key->regions;

=back

=cut

sub regions {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{regions};
}

=head2 name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $name = $ssh_key->name;

=back

=cut

sub name {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{name};
}

=head2 public_key

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $public_key = $ssh_key->public_key;

=back

=cut

sub public_key {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{publicKey};
}

=head2 delete

Deletes the object api sided and sets it invalid.

=over

=item * Synopsis: $ssh_key->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $key_id     = $self->id;

    my $response = $api->rawCall( method => 'delete', path => "/cloud/project/$project_id/sshkey/$key_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

1;
