package Webservice::OVH::Cloud::Project::Instance;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::Instance

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    my $example_project = $projects->[0];
    
    my $instances = $project->instances;
    
    foreach my $instance (@$instances) {
        
        print @$instance->status;
        $instance->delete;
    }

=head1 DESCRIPTION

Access to instace functionality.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use JSON;

our $VERSION = 0.43;

use Webservice::OVH::Cloud::Project::Instance::Group;

# Static Methods

=head2 _new_empty

Internal Method to create the Network object.
This method is not ment to be called directly.
This method is used when instance is initialised as a bridge object for static usage.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Instance>

=item * Synopsis: Webservice::OVH::Cloud::Project::Instance->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new_empty {

    my ( $class, %params ) = @_;
    
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing project"      unless $params{project};

    my $module       = $params{module};
    my $api_wrapper  = $params{wrapper};
    my $project      = $params{project};

    my $self = bless { _module => $module, _valid => 0, _api_wrapper => $api_wrapper, _project => $project, _available_groups => [], _groups => {} }, $class;
}

=head2 group_exists

Returns 1 if object is available, 0 if not.

=over

=item * Parameter: $group_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "group exists" if $project->group_exists($id);

=back

=cut

sub group_exists {

    my ( $self, $group_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->project->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/group", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        return ( grep { $_ eq $group_id } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_available_groups};

        return ( grep { $_ eq $group_id } @$list ) ? 1 : 0;
    }
}

=head2 groups

Produces an array of all available groups that are connected to the instance.

=over

=item * Return: ARRAY

=item * Synopsis: my $instances = $instance->groups;

=back

=cut

sub groups {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->{_project}->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/group", noSignature => 0 );
    croak $response->error if $response->error;

    my $group_array = $response->content;
    my $groups      = [];
    $self->{_available_groups} = $group_array;

    foreach my $group_id (@$group_array) {
        if ( $self->group_exists( $group_id, 1 ) ) {
            my $group = $self->{_groups}{$group_id} = $self->{_groups}{$group_id} || Webservice::OVH::Cloud::Project::Instance::Group->_new_existing( wrapper => $api, module => $self->{_module}, project => $self->project, id => $group_id );
            push @$groups, $group;
        }
    }

    return $groups;
}

=head2 group

Returns a single group by id

=over

=item * Parameter: $group_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::Instance::Group>

=item * Synopsis: my $instance = $isntance->group($id);

=back

=cut

sub group {

    my ( $self, $group_id ) = @_;

    if ( $self->group_exists($group_id) ) {

        my $api = $self->{_api_wrapper};
        my $instance = $self->{_group}{$group_id} = $self->{_group}{$group_id} || Webservice::OVH::Cloud::Project::Instance->_new_existing( wrapper => $api, module => $self->{_module}, project => $self->project, id => $group_id );

        return $instance;
    } else {

        carp "Instance $group_id doesn't exists";
        return undef;
    }
}

=head2 create_group

Creates a new group

=over

=item * Parameter: %params - key => value (required) region

=item * Return: <Webservice::OVH::Cloud::Project::Instance::Group>

=item * Synopsis: my $group = $project->create_instance( region => 'GRA1' );

=back

=cut

sub create_group {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $group = Webservice::OVH::Cloud::Project::Instance::Group->_new( wrapper => $api, module => $self->{_module}, project => $self->project, %params );
}

=head2 _new_existing

Internal Method to create the Instance object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Instance>

=item * Synopsis: Webservice::OVH::Cloud::Project::Instance->_new( wrapper => $ovh_api_wrapper, project => $project, module => $module, id => $id );

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing id"      unless $params{id};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing project" unless $params{project};

    my $instance_id = $params{id};
    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $project     = $params{project};
    my $project_id  = $project->id;

    my $response = $api_wrapper->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/$instance_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $porperties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $instance_id, _properties => $porperties, _project => $project }, $class;

        return $self;
    } else {

        return undef;
    }
}

=head2 _new

Internal Method to create the Instance object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::Instance>

=item * Synopsis: Webservice::OVH::Cloud::Project::Instance->_new(wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing project" unless $params{project};

    my @keys = qw{ flavor_id image_id name region };
    if ( my @missing_parameters = grep { not $params{$_} } @keys ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $project     = $params{project};
    my $project_id  = $project->id;

    my $monthly_billing = $params{monthly_billing} && ( $params{monthly_billing} eq 'true' || $params{monthly_billing} eq 'yes' || $params{monthly_billing} eq '1' ) ? JSON::true : JSON::false;

    my $body = {};
    $body->{flavorId}       = $params{flavor_id};
    $body->{imageId}        = $params{image_id};
    $body->{name}           = $params{name};
    $body->{region}         = $params{region};
    $body->{groupId}        = $params{group_id} if exists $params{group_id};
    $body->{monthlyBilling} = $monthly_billing;
    $body->{sshKeyId}       = $params{ssh_key_id} if exists $params{ssh_key_id};
    $body->{userData}       = $params{user_data} if exists $params{user_data};

    my $networks = $params{networks};

    foreach my $network (@$networks) {

        push @{ $body->{networks} }, { ip => $network->{ip}, networkId => $network->{network_id} };
    }

    my $response = $api_wrapper->rawCall( method => 'post', path => "/cloud/project/$project_id/instance", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $instance_id = $response->content->{id};
    my $properties  = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $instance_id, _properties => $properties, _project => $project }, $class;

    return $self;
}

=head2 id

Returns the api id 

=over

=item * Return: VALUE

=item * Synopsis: my $id = $instance->id;

=back

=cut

sub id {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_id};
}

=head2 is_valid

When this object is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $instance->is_valid;

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

=item * Synopsis: $instance->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    carp "Instance is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 project

Root Project.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $instance->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_project};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $instance->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api        = $self->{_api_wrapper};
    my $id         = $self->id;
    my $project_id = $self->project->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/instance/group/$id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $instance->description;

=back

=cut

sub description {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{description};
}

=head2 status

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $status = $instance->status;

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

=item * Synopsis: my $name = $instance->name;

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

=item * Synopsis: my $region = $instance->region;

=back

=cut

sub region {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{region};
}

=head2 image

Exposed property value. 

=over

=item * Return: <Webservice::OVH::Cloud::Project::Image>

=item * Synopsis: my $image = $instance->image;

=back

=cut

sub image {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $image_id = $self->{_properties}->{image}->{id};

    my $image = $self->project->images($image_id);

    return $image;
}

=head2 created

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $dt_created = $instance->created;

=back

=cut

sub created {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $str_datetime = $self->{_properties}->{created};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 ssh_key

Exposed property value. 

=over

=item * Return: <Webservice::OVH::Cloud::Project::SSH>

=item * Synopsis: my $ssh_key = $instance->ssh_key;

=back

=cut

sub ssh_key {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $key_id = $self->{_properties}->{sshKey}->{id};

    my $key = $self->project->images($key_id);

    return $key;
}

=head2 monthly_billing

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $monthly_billing = $instance->monthly_billing;

=back

=cut

sub monthly_billing {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{monthlyBilling};
}

=head2 ip_addresses

Exposed property value. 

=over

=item * Return: ARRAY

=item * Synopsis: my $ip_addresses = $instance->ip_addresses;

=back

=cut

sub ip_addresses {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{ipAddresses};
}

=head2 flavor

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $flavor = $instance->flavor;

=back

=cut

sub flavor {

    my ($self) = @_;

    return unless $self->_is_valid;

    return $self->{_properties}->{flavor};
}

=head2 change

Changes the instance.

=over

=item * Parameter: $instance_name - instance name

=item * Synopsis: $instance->change('Test Instance');

=back

=cut

sub change {

    my ( $self, $instance_name ) = @_;

    return unless $self->_is_valid;

    croak "Missing instance_name" unless $instance_name;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'put', path => "/cloud/project/$project_id/instance/$instance_id", body => { instanceName => $instance_name }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 delete

Deletes the object api sided and sets it invalid.

=over

=item * Synopsis: $instance->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project->id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'delete', path => "/cloud/project/$project_id/instance/$instance_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

=head2 delete

Activates monthly billing for rinstance.

=over

=item * Synopsis: $instance->active_monthly_billing;

=back

=cut

sub active_monthly_billing {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/activeMonthlyBilling", body => {}, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 delete

Return many statistics about the virtual machine for a given period

=over

=item * Return: HASH

=item * Synopsis: $instance->monitoring;

=back

=cut

sub monitoring {

    my ( $self, $period, $type ) = @_;

    return unless $self->_is_valid;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $filter = Webservice::OVH::Helper->construct_filter( period => $period, type => $type );

    my $response = $api->rawCall( method => 'get', path => sprintf( "/cloud/project/$project_id/instance/$instance_id/monitoring%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 reboot

Reboots the instance. Options are soft or hard.

=over

=item * Parameter: $type - soft hard

=item * Synopsis: $instance->reboot;

=back

=cut

sub reboot {

    my ( $self, $type ) = @_;

    return unless $self->_is_valid;

    croak "Missing or wrong reboot type: hard, soft" unless $type && ( $type eq 'hard' || $type eq 'soft' );

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/reboot", body => { type => $type }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 reinstall

Reinstall an instance.

=over

=item * Parameter: $image_id - image id

=item * Synopsis: $instance->reboot;

=back

=cut

sub reinstall {

    my ( $self, $image_id ) = @_;

    return unless $self->_is_valid;

    croak "Missing image_id" unless $image_id;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/reinstall", body => { imageId => $image_id }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 rescue_mode

Enable or disable rescue mode.

=over

=item * Parameter: $rescue - enabled or not (true/1), (optional) $image_id - image id

=item * Synopsis: $instance->reboot;

=back

=cut

sub rescue_mode {

    my ( $self, $rescue, $image_id ) = @_;

    return unless $self->_is_valid;

    croak "Missing image" unless $rescue;

    my $rescue_mode = $rescue && ( $rescue eq 'true' || $rescue eq '1' || $rescue eq 'yes' ) ? JSON::true : JSON::false;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;
    my $body        = {};
    $body->{imageId} = $image_id if $image_id;
    $body->{rescue} = $rescue_mode;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/reinstall", body => $body, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 resize

Migrate your instance to another flavor.

=over

=item * Parameter: $rescue - enabled or not (true/1), (optional) $image_id - image id

=item * Synopsis: $instance->resize($flavor_id);

=back

=cut

sub resize {

    my ( $self, $flavor_id ) = @_;

    return unless $self->_is_valid;

    croak "Missing flavor_id" unless $flavor_id;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/resize", body => { flavorId => $flavor_id }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 snapshot

Snapshot an instance.

=over

=item * Parameter: $snapshotName - Name of the snapshot

=item * Synopsis: $instance->snapshotName("Snapshot1");

=back

=cut

sub snapshot {

    my ( $self, $snapshot_name ) = @_;

    return unless $self->_is_valid;

    croak "Missing snapshot_name" unless $snapshot_name;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/snapshot", body => { snapshotName => $snapshot_name }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 vnc

Get VNC access to your instance.

=over

=item * Synopsis: $instance->vnc;

=back

=cut

sub vnc {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api         = $self->{_api_wrapper};
    my $project_id  = $self->project_id;
    my $instance_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/cloud/project/$project_id/instance/$instance_id/vnc", body => {}, noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

1;
