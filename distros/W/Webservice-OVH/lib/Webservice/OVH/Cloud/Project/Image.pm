package Webservice::OVH::Cloud::Project::Image;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Image

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $images = $project->images;
    
    foreach my $image (@$images) {
        
        print $image->type;
    }

=head1 DESCRIPTION

Provides access to information about an image. Nothing more can be done with this.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.3;

=head2 _new_existing

Internal Method to create the image object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Image>

=item * Synopsis: Webservice::OVH::Cloud::Project::Image->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing project" unless $params{project};

    my $project     = $params{project};
    my $project_id  = $project->id;
    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};
    my $image_id    = $params{id};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/cloud/project/$project_id/image/$image_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $image_id, _properties => $porperties, _project => $project }, $class;

        return $self;
    } else {

        return undef;
    }
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

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $image->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $image->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $image_id   = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/image/$image_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 visibility

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $visibility = $image->visibility;

=back

=cut

sub visibility {

    my ($self) = @_;

    return $self->{_properties}->{visibility};
}

=head2 status

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $status = $image->status;

=back

=cut

sub status {

    my ($self) = @_;

    return $self->{_properties}->{status};
}

=head2 name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $name = $image->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_properties}->{name};
}

=head2 region

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $region = $image->region;

=back

=cut

sub region {

    my ($self) = @_;

    return $self->{_properties}->{region};
}

=head2 min_disk

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $min_disk = $image->min_disk;

=back

=cut

sub min_disk {

    my ($self) = @_;

    return $self->{_properties}->{minDisk};
}

=head2 size

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $size = $image->size;

=back

=cut

sub size {

    my ($self) = @_;

    return $self->{_properties}->{size};
}

=head2 creation_date

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $creation_date = $image->creation_date;

=back

=cut

sub creation_date {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{creationDate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 min_ram

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $min_ram = $image->min_ram;

=back

=cut

sub min_ram {

    my ($self) = @_;

    return $self->{_properties}->{minRam};
}

=head2 user

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $user = $image->user;

=back

=cut

sub user {

    my ($self) = @_;

    return $self->{_properties}->{user};
}

=head2 type

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $type = $image->type;

=back

=cut

sub type {

    my ($self) = @_;

    return $self->{_properties}->{type};
}

1;
