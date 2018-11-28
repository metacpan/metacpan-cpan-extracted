package Webservice::OVH::Cloud::Project;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $images = $project->images;
    my $instances = $project->instances;
    my $regions = $project->regions;
    my $flavors = $project->flavors;
    my $ssh_keys = $project->ssh_keys;
    my $networks = $project->network->privates;

=head1 DESCRIPTION

Provides access to all sub objects of a specific projects.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

use Webservice::OVH::Cloud::Project::IP;
use Webservice::OVH::Cloud::Project::Instance;
use Webservice::OVH::Cloud::Project::Network;
use Webservice::OVH::Cloud::Project::Image;
use Webservice::OVH::Cloud::Project::SSH;

=head2 _new_existing

Internal Method to create the project object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $id - api id

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: Webservice::OVH::Cloud::Project->_new($ovh_api_wrapper, $project_name, $module);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};

    my $project_id  = $params{id};
    my $api_wrapper = $params{wrapper};
    my $module      = $params{module};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _properties => undef, _id => $project_id, _instances => {}, _available_instances => [], _images => {}, _available_images => [], _ssh_keys => {}, _available_ssh_keys => [] }, $class;

    my $instance = Webservice::OVH::Cloud::Project::Instance->_new_empty( wrapper => $api_wrapper, project => $self, module => $module );
    my $network = Webservice::OVH::Cloud::Project::Network->_new( wrapper => $api_wrapper, project => $self, module => $module );
    my $ip = Webservice::OVH::Cloud::Project::IP->_new( wrapper => $api_wrapper, project => $self, module => $module );

    $self->{_instance} = $instance;
    $self->{_network}  = $network;
    $self->{_ip}       = $ip;

    $self->properties;

    return $self;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $project->id;

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

=item * Synopsis: my $properties = $project->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $id       = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/cloud/project/$id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $project->description;

=back

=cut

sub description {

    my ($self) = @_;

    return $self->{_properties}->{description};
}

=head2 unleash

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $sub_domain = $project->unleash;

=back

=cut

sub unleash {

    my ($self) = @_;

    return $self->{_properties}->{unleash} eq 'true' ? 1 : 0;
}

=head2 order

Exposed property value. 

=over

=item * Return: <Webservice::OVH::Me::Order>

=item * Synopsis: my $order = $project->order;

=back

=cut

sub order {

    my ($self) = @_;

    my $order_id = $self->{_properties}->{orderId};

    return $self->{_module}->me->order($order_id) if $order_id;

    return undef;
}

=head2 status

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $status = $project->status;

=back

=cut

sub status {

    my ($self) = @_;

    return $self->{_properties}->{status};
}

=head2 access

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $access = $project->access;

=back

=cut

sub access {

    my ($self) = @_;

    return $self->{_properties}->{access};
}

=head2 change

Changes the project.

=over

=item * Parameter: %params - key => value description

=item * Synopsis: $project->change(description => 'Beschreibung');

=back

=cut

sub change {

    my ( $self, $description ) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;

    my $response = $api->rawCall( method => 'put', path => "/cloud/project/$project_id", body => { description => $description }, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;
}

=head2 vrack

Get associated vrack.

=over

=item * Return: HASH

=item * Synopsis: $project->vrack;

=back

=cut

sub vrack {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/vrack", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 instance_exists

Returns 1 if object is available for the connected account, 0 if not.

=over

=item * Parameter: $instance_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "instance exists" if $project->instance_exists($id);

=back

=cut

sub instance_exists {

    my ( $self, $instance_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/instance", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;
        my @instance_ids = grep { $_ = $_->{id} } @$list;

        return ( grep { $_ eq $instance_id } @instance_ids ) ? 1 : 0;

    } else {

        my $list = $self->{_available_instances};

        return ( grep { $_ eq $instance_id } @$list ) ? 1 : 0;
    }
}

=head2 instances

Produces an array of all available instances that are connected to the project.

=over

=item * Return: ARRAY

=item * Synopsis: my $instances = $project->instances;

=back

=cut

sub instances {

    my ( $self, $region ) = @_;

    my $filter     = $region ? Webservice::OVH::Helper->construct_filter( "region" => $region ) : "";
    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => sprintf( "/cloud/project/$project_id/instance%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $instance_array = $response->content;
    my $instances      = [];
    my @instance_ids   = grep { $_ = $_->{id} } @$instance_array;
    $self->{_available_images} = \@instance_ids;

    foreach my $instance_id (@instance_ids) {

        if ( $self->instance_exists( $instance_id, 1 ) ) {
            my $instance = $self->{_instances}{$instance_id} = $self->{_instances}{$instance_id} || Webservice::OVH::Cloud::Project::Instance->_new_existing( wrapper => $api, project => $self, id => $instance_id, module => $self->{_module} );
            push @$instances, $instance;
        }
    }

    return $instances;
}

=head2 instance

Returns a single instance by id

=over

=item * Parameter: $instance_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::Instance>

=item * Synopsis: my $instance = $project->instance($id);

=back

=cut

sub instance {

    my ( $self, $instance_id ) = @_;

    if ( !$instance_id ) {

        return $self->{_instance};

    } else {

        if ( $self->instance_exists($instance_id) ) {

            my $api = $self->{_api_wrapper};
            my $instance = $self->{_instances}{$instance_id} = $self->{_instances}{$instance_id} || Webservice::OVH::Cloud::Project::Instance->_new_existing( wrapper => $api, project => $self, id => $instance_id, module => $self->{_module} );

            return $instance;
        } else {

            carp "Instance $instance_id doesn't exists";
            return undef;
        }
    }
}

=head2 create_instance

Creates a new instance. Flavor image and ssh key need to be fetched first.
There is an example in examples/cloud.pl 

=over

=item * Parameter: %params - key => value (required) flavor_id image_id name region (optional) group_id monthly_billing ssh_key_id user_data networks

=item * Return: <Webservice::OVH::Cloud::Project::Instance>

=item * Synopsis: my $instance = $project->create_instance(flavor_id => $flavor->id, image_id => $image->id, name => 'test', region => 'GRA1', ssh_key => $key->id networks => [ {ip => '0.0.0.0', network_id => 1 }, {ip => '0.0.0.0', network_id => 2 } ] );

=back

=cut

sub create_instance {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $instance = Webservice::OVH::Cloud::Project::Instance->_new( wrapper => $api, module => $self->{_module}, project => $self, %params, );
    return $instance;
}

=head2 regions

Simple list of all available regions

=over

=item * Return: ARRAY

=item * Synopsis: my $regions = $project->regions;

=back

=cut

sub regions {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/region", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 regions

Get additional info about a specific region

=over

=item * Return: HASH

=item * Synopsis: my $region_info = $project->region('GRA1');

=back

=cut

sub region {

    my ( $self, $region_name ) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/region/$region_name", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 flavors

Returns a hash of all available flavors.

=over

=item * Return: ARRAY

=item * Synopsis: my $flavors = $project->flavors;

=back

=cut

sub flavors {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/flavor", noSignature => 0 );
    croak $response->error if $response->error;

    my @flavor_ids = grep { $_->{id} } @{ $response->content };

    return \@flavor_ids;
}

=head2 flavor

Returns info about a specific flavor by id.

=over

=item * Return: HASH

=item * Synopsis: my $flavors = $project->flavors;

=back

=cut

sub flavor {

    my ( $self, $flavor_id ) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/flavor/$flavor_id", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 image_exists

Returns 1 if image is available for the project, 0 if not.

=over

=item * Parameter: $image_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "image exists" if $project->image_exists(1234);

=back

=cut

sub image_exists {

    my ( $self, $image_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/image", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        my @image_ids = grep { $_ = $_->{id} } @$list;

        return ( grep { $_ eq $image_id } @image_ids ) ? 1 : 0;

    } else {

        my $list = $self->{_available_images};

        return ( grep { $_ eq $image_id } @$list ) ? 1 : 0;
    }
}

=head2 images

Produces an array of all available images that are connected to the project.

=over

=item * Parameter: %filter - key => value flavor_type os_type region

=item * Return: ARRAY

=item * Synopsis: my $images = $project->images( flavor_type => 'ovh.ssd.eg', os_type => 'linux', region => 'GRA1' );

=back

=cut

sub images {

    my ( $self, %filter ) = @_;

    my %filter_values;
    $filter_values{flavorType} = $filter{flavor_type} unless exists $filter{flavor_type};
    $filter_values{osType}     = $filter{os_type}     unless exists $filter{os_type};
    $filter_values{region}     = $filter{region}      unless exists $filter{region};
    my $filter = Webservice::OVH::Helper->construct_filter(%filter);

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => sprintf( "/cloud/project/$project_id/image%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $image_array = $response->content;
    my $images      = [];
    my @image_ids   = grep { $_ = $_->{id} } @$image_array;
    $self->{_available_images} = \@image_ids;

    foreach my $image_id (@image_ids) {

        if ( $self->image_exists( $image_id, 1 ) ) {

            my $image = $self->{_images}{$image_id} = $self->{_images}{$image_id} || Webservice::OVH::Cloud::Project::Image->_new_existing( wrapper => $api, module => $self->{_module}, project => $self, id => $image_id );
            push @$images, $image;
        }
    }

    return $images;
}

=head2 image

Returns a single image by id

=over

=item * Parameter: $image_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::Image>

=item * Synopsis: my $image = $project->image($id);

=back

=cut

sub image {

    my ( $self, $image_id ) = @_;

    if ( $self->image_exists($image_id) ) {

        my $api = $self->{_api_wrapper};
        my $instance = $self->{_image}{$image_id} = $self->{_image}{$image_id} || Webservice::OVH::Cloud::Project::Image->_new_existing( wrapper => $api, module => $self->{_module}, project => $self, id => $image_id );

        return $instance;
    } else {

        carp "Instance $image_id doesn't exists";
        return undef;
    }
}

=head2 ssh_key_exists

Returns 1 if key is available for the project, 0 if not.

=over

=item * Parameter: $key_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "image exists" if $project->image_exists(1234);

=back

=cut

sub ssh_key_exists {

    my ( $self, $key_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/sshkey", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;
        my @key_ids = grep { $_ = $_->{id} } @$list;

        return ( grep { $_ eq $key_id } @key_ids ) ? 1 : 0;

    } else {

        my $list = $self->{_available_ssh_keys};

        return ( grep { $_ eq $key_id } @$list ) ? 1 : 0;
    }
}

=head2 ssh_keys

Produces an array of all available ssh_keys that are connected to the project.

=over

=item * Parameter: $region - filters for specific region

=item * Return: ARRAY

=item * Synopsis: my $keys = $project->images( region => 'GRA1' );

=back

=cut

sub ssh_keys {

    my ( $self, $region ) = @_;

    my $filter = $region ? Webservice::OVH::Helper->construct_filter( region => $region ) : "";

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->id;
    my $response   = $api->rawCall( method => 'get', path => sprintf( "/cloud/project/$project_id/sshkey%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $key_array = $response->content;
    my $keys      = [];
    my @key_ids   = grep { $_ = $_->{id} } @$key_array;
    $self->{_available_ssh_keys} = \@key_ids;

    foreach my $key_id (@key_ids) {

        if ( $self->ssh_key_exists( $key_id, 1 ) ) {

            my $ssh_key = $self->{_ssh_keys}{$key_id} = $self->{_ssh_keys}{$key_id} || Webservice::OVH::Cloud::Project::SSH->_new_existing( wrapper => $api, module => $self->{_module}, project => $self, id => $key_id );
            push @$keys, $ssh_key;
        }
    }

    return $keys;
}

=head2 ssh_key

Returns a single ssh_key by id

=over

=item * Parameter: $key_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::SSH>

=item * Synopsis: my $ssh_key = $project->ssh_key($id);

=back

=cut

sub ssh_key {

    my ( $self, $key_id ) = @_;

    if ( $self->ssh_key_exists($key_id) ) {

        my $api = $self->{_api_wrapper};
        my $instance = $self->{_ssh_keys}{$key_id} = $self->{_ssh_keys}{$key_id} || Webservice::OVH::Cloud::Project::SSH->_new_existing( wrapper => $api, module => $self->{_module}, project => $self, id => $key_id );

        return $instance;
    } else {

        carp "SSH-Key $key_id doesn't exists";
        return undef;
    }
}

=head2 create_ssh_key

Creates a new ssh key. 

=over

=item * Parameter: %params - key => value (required) name public_key (optional) region

=item * Return: <Webservice::OVH::Cloud::Project::SSH>

=item * Synopsis: my $ssh_key = $project->create_ssh_key( name => 'Test key', public_key => $key );

=back

=cut

sub create_ssh_key {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $ssh_key = Webservice::OVH::Cloud::Project::SSH->_new( wrapper => $api, module => $self->{_module}, project => $self, %params, );
    return $ssh_key;
}

=head2 network

Access to /cloud/project/network api methods 

=over

=item * Return: L<Webservice::OVH::Cloud::Project::Network>

=item * Synopsis: $project->network;

=back

=cut

sub network {

    my ($self) = @_;

    return $self->{_network};
}

=head2 ip

Access to /cloud/project/ip api methods 

=over

=item * Return: L<Webservice::OVH::Cloud::Project::IP>

=item * Synopsis: $project->ip;

=back

=cut

sub ip {

    my ($self) = @_;

    return $self->{_ip};
}

1;
