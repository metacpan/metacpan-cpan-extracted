package Webservice::OVH::Cloud;

=encoding utf-8

=head1 NAME

Webservice::OVH::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $projects = $ovh->cloud->projects;
    foreach my $project (@$project) {
        
        print $project->name;
    }
    
    print "I have a project" if $ovh->cloud->project_exists("Name");

=head1 DESCRIPTION

Gives access to projects connected to the used account.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.46;

use Webservice::OVH::Cloud::Project;

=head2 _new

Internal Method to create the cloud object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Project>

=item * Synopsis: Webservice::OVH::Clooud->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _projects => {}, _avaiable_projects => [] }, $class;

    return $self;
}

=head2 project_exists

Returns 1 if project is available for the connected account, 0 if not.

=over

=item * Parameter: $project_name - Domain name, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "Name exists" if $ovh->domain->project_exists("Name");

=back

=cut

sub project_exists {

    my ( $self, $id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api = $self->{_api_wrapper};
        my $response = $api->rawCall( method => 'get', path => "/cloud/project", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        return ( grep { $_ eq $id } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_avaiable_projects};

        return ( grep { $_ eq $id } @$list ) ? 1 : 0;
    }
}

=head2 projects

Produces an array of all available projects that are connected to the used account.

=over

=item * Return: ARRAY

=item * Synopsis: my $projects = $ovh->order->projects();

=back

=cut

sub projects {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/cloud/project", noSignature => 0 );
    croak $response->error if $response->error;

    my $project_array = $response->content;
    my $projects      = [];
    $self->{_avaiable_projects} = $project_array;

    foreach my $project_id (@$project_array) {
        if ( $self->project_exists( $project_id, 1 ) ) {
            my $project = $self->{_projects}{$project_id} = $self->{_projects}{$project_id} || Webservice::OVH::Cloud::Project->_new_existing( wrapper => $api, id => $project_id, module => $self->{_module} );
            push @$projects, $project;
        }
    }

    return $projects;
}

=head2 project

Returns a single project by name

=over

=item * Parameter: $project_name - project name

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $ovh->cloud->project("Name");

=back

=cut

sub project {

    my ( $self, $project_id ) = @_;

    if ( $self->project_exists($project_id) ) {

        my $api = $self->{_api_wrapper};
        my $project = $self->{_projects}{$project_id} = $self->{_projects}{$project_id} || Webservice::OVH::Cloud::Project->_new_existing( wrapper => $api, id => $project_id, module => $self->{_module} );

        return $project;
    } else {

        carp "Service $project_id doesn't exists";
        return undef;
    }
}

=head2 create_project

Price information for projects and other running cloud services 

=over

=item * Parameter: $description - (optional) description, $voucher - (optional)

=item * Return: Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $order = $ovh->cloud->create_project;

=back

=cut

sub create_project {

    my ( $self, %params ) = @_;

    my $api  = $self->{_api_wrapper};
    my $body = {};
    $body->{description} = $params{description} if exists $params{description};
    $body->{voucher}     = $params{voucher}     if exists $params{voucher};
    my $response = $api->rawCall( method => 'post', path => "/cloud/createProject", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $order_id = $response->content->{orderId};

    return $self->{_module}->me->order($order_id);
}

=head2 price

Price information for projects and other running cloud services 

=over

=item * Parameter: $flavor_id - Cloud flavor id, $region - region

=item * Return: HASH

=item * Synopsis: my $prices = $ovh->cloud->price;

=back

=cut

sub price {

    my ( $self, $flavor_id, $region ) = @_;

    my $filter = Webservice::OVH::Helper->construct_filter( "flavorId" => $flavor_id, "region" => $region );

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => sprintf( "/cloud/price%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

1;
