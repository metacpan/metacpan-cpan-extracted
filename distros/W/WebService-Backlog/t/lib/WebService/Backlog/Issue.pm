package WebService::Backlog::Issue;

# $Id: Issue.pm 600 2008-05-09 13:48:50Z yamamoto $

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw/
      id key summary description url due_date created_on updated_on
      issueType priority
      component components
      resolution
      version versions
      status
      milestone milestones
      created_user assigner
      /
);

sub new {
    my $self = shift->SUPER::new(@_);
    $self->issueType( $self->_issueType_accessor );
    $self->priority( $self->_priority_accessor );
    $self->component( $self->_component_accessor );
    $self->components( $self->_components_accessor );
    $self->resolution( $self->_resolution_accessor );
    $self->version( $self->_version_accessor );
    $self->versions( $self->_versions_accessor );
    $self->status( $self->_status_accessor );
    $self->milestone( $self->_milestone_accessor );
    $self->milestones( $self->_milestones_accessor );
    $self->created_user( $self->_created_user_accessor );
    $self->assigner( $self->_assigner_accessor );
    return $self;
}

use WebService::Backlog::IssueType;
use WebService::Backlog::Priority;
use WebService::Backlog::Component;
use WebService::Backlog::Resolution;
use WebService::Backlog::Version;
use WebService::Backlog::Status;
use WebService::Backlog::User;

sub issueType {
    my $self = shift;
    $self->_issueType_accessor( WebService::Backlog::IssueType->new(@_) )
      if (@_);
    return $self->_issueType_accessor;
}

sub priority {
    my $self = shift;
    $self->_priority_accessor( WebService::Backlog::Priority->new(@_) ) if (@_);
    return $self->_priority_accessor;
}

=head2 component

This method is deprecated.
use "components" instead.

=cut

sub component {
    my $self = shift;
    $self->_component_accessor( WebService::Backlog::Component->new(@_) )
      if ( @_ && $_[0] && $_[0]->{id} );
    return $self->_component_accessor;
}

sub components {
    my $self = shift;
    if ( @_ && ref( $_[0] ) eq 'ARRAY' ) {
        my @components = ();
        for my $c ( @{ $_[0] } ) {
            push( @components, WebService::Backlog::Component->new($c) );
        }
        return $self->_components_accessor( \@components );
    }
    return $self->_components_accessor;
}

sub resolution {
    my $self = shift;
    $self->_resolution_accessor( WebService::Backlog::Resolution->new(@_) )
      if ( @_ && $_[0] && defined( $_[0]->{id} ) );
    return $self->_resolution_accessor;
}

=head2 version

This method is deprecated.
use "versions" instead.

=cut

sub version {
    my $self = shift;
    $self->_version_accessor( WebService::Backlog::Version->new(@_) )
      if ( @_ && $_[0] && $_[0]->{id} );
    return $self->_version_accessor;
}

sub versions {
    my $self = shift;
    if ( @_ && ref( $_[0] ) eq 'ARRAY' ) {
        my @versions = ();
        for my $c ( @{ $_[0] } ) {
            push( @versions, WebService::Backlog::Version->new($c) );
        }
        return $self->_versions_accessor( \@versions );
    }
    return $self->_versions_accessor;
}

sub status {
    my $self = shift;
    $self->_status_accessor( WebService::Backlog::Status->new(@_) ) if (@_);
    return $self->_status_accessor;
}

=head2 version

This method is deprecated.
use "milestones" instead.

=cut

sub milestone {
    my $self = shift;
    $self->_milestone_accessor( WebService::Backlog::Version->new(@_) )
      if ( @_ && $_[0] && $_[0]->{id} );
    return $self->_milestone_accessor;
}

sub milestones {
    my $self = shift;
    if ( @_ && ref( $_[0] ) eq 'ARRAY' ) {
        my @milestones = ();
        for my $c ( @{ $_[0] } ) {
            push( @milestones, WebService::Backlog::Version->new($c) );
        }
        return $self->_milestones_accessor( \@milestones );
    }
    return $self->_milestones_accessor;
}

sub created_user {
    my $self = shift;
    $self->_created_user_accessor( WebService::Backlog::User->new(@_) ) if (@_);
    return $self->_created_user_accessor;
}

sub assigner {
    my $self = shift;
    $self->_assigner_accessor( WebService::Backlog::User->new(@_) )
      if ( @_ && $_[0] && $_[0]->{id} );
    return $self->_assigner_accessor;
}

1;
__END__
