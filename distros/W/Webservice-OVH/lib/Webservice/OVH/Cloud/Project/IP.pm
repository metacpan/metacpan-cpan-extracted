package Webservice::OVH::Cloud::Project::IP;

=encoding utf-8

=head1 NAME

Webservice::OVH::Cloud::Project::IP;

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

Bridge Object failover ips

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.43;

use Webservice::OVH::Cloud::Project::IP::Failover;

=head2 _new_existing

Internal Method to create the object.
This method is not ment to be called directly.

=over

=item * Parameter: %params - key => value

=item * Return: L<Webservice::OVH::Cloud::Project::IP>

=item * Synopsis: Webservice::OVH::Cloud::Project::IP->_new( wrapper => $ovh_api_wrapper, project => $project, module => $module );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing project" unless $params{project};
    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $self = bless { module => $params{module}, _api_wrapper => $params{wrapper}, _project => $params{project}, _available_failovers => [], _failovers => {} }, $class;

    return $self;
}

=head2 project

Shorthand to call $self->project directly for internal usage.

=over

=item * Return: L<Webservice::OVH::Cloud::Project>

=item * Synopsis: my $project = $project->ip->project;

=back

=cut

sub project {

    my ($self) = @_;

    return $self->{_project};
}

=head2 failover_exists

Returns 1 if failover is available for the connected account, 0 if not.

=over

=item * Parameter: $failover_id - api id, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "failover exists" if $project->ip->failover_exists(1234);

=back

=cut

sub failover_exists {

    my ( $self, $failover_id, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api        = $self->{_api_wrapper};
        my $project_id = $self->project->id;
        my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/ip/failover", noSignature => 0 );
        croak $response->error if $response->error;

        my $list = $response->content;

        return ( grep { $_ eq $failover_id } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_avaiable_projects};

        return ( grep { $_ eq $failover_id } @$list ) ? 1 : 0;
    }
}

=head2 failovers

Produces an array of all available failovers that are connected to the project.

=over

=item * Return: ARRAY

=item * Synopsis: my $ips = $project->ip->failovers;

=back

=cut

sub failovers {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $project_id = $self->project->id;
    my $response   = $api->rawCall( method => 'get', path => "/cloud/project/$project_id/ip/failover", noSignature => 0 );
    croak $response->error if $response->error;

    my $failover_array = $response->content;
    my $failovers      = [];
    $self->{_available_failovers} = $failover_array;

    foreach my $failover_hash (@$failover_array) {

        my $failover_id = $failover_hash->{id};
        if ( $self->failover_exists( $failover_id, 1 ) ) {
            my $failover = $self->{_failovers}{$failover_id} = $self->{_failovers}{$failover_id} || Webservice::OVH::Cloud::Project::IP::Failover->_new( wrapper => $api, project => $self->project, id => $failover_id, module => $self->{_module} );
            push @$failovers, $failover;
        }
    }

    return $failovers;
}

=head2 failover

Returns a single failover by id

=over

=item * Parameter: $failover_id - api id

=item * Return: L<Webservice::OVH::Cloud::Project::IP::Failover>

=item * Synopsis: my $failover = $project->ip->failover(1234);

=back

=cut

sub failover {

    my ( $self, $failover_id ) = @_;

    if ( $self->failover_exists($failover_id) ) {

        my $api = $self->{_api_wrapper};
        my $failover = $self->{_failovers}{$failover_id} = $self->{_failovers}{$failover_id} || Webservice::OVH::Cloud::Project::IP::Failover->_new( wrapper => $api, project => $self->project, id => $failover_id, module => $self->{_module} );

        return $failover;
    } else {

        carp "Failover $failover_id doesn't exists";
        return undef;
    }
}

1;
