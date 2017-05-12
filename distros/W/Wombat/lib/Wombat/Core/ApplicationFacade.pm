# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::ApplicationFacade;

=pod

=head1 NAME

Wombat::Core::ApplicationFacade - internal application facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal Application object. All methods
are delegated to the wrapped application. The facade is presented to
servlet code so that the servlet code does not have access to internal
Application methods.

=cut

use base qw(Servlet::ServletContext);
use fields qw(application);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new($application)

Construct and return a B<Wombat::Connector::ApplicationFacade>
instance. If subclasses override the constructor, they must be sure to
call

  $self->SUPER::new($application);

B<Parameters:>

=over

=item $application

the B<Wombat::Core::Application> for which this object is the facade.

=back

=back

=cut

sub new {
    my $self = shift;
    my $application = shift;

    $self = fields::new($self) unless ref $self;

    $self->{application} = $application;

    return $self;
}

sub getAttribute {
    my $self = shift;

    return $self->{application}->getAttribute(@_);
}

sub getAttributeNames {
    my $self = shift;

    return $self->{application}->getAttributeNames(@_);
}

sub removeAttribute {
    my $self = shift;

    return $self->{application}->removeAttribute(@_);
}

sub setAttribute {
    my $self = shift;

    return $self->{application}->setAttribute(@_);
}

sub getContext {
    my $self = shift;

    return $self->{application}->getContext(@_);
}

sub getInitParameter {
    my $self = shift;

    return $self->{application}->getInitParameter(@_);
}

sub getInitParameterNames {
    my $self = shift;

    return $self->{application}->getInitParameterNames(@_);
}

sub getMajorVersion {
    my $self = shift;

    return $self->{application}->getMajorVersion(@_);
}

sub getMinorVersion {
    my $self = shift;

    return $self->{application}->getMinorVersion(@_);
}

sub getMimeType {
    my $self = shift;

    return $self->{application}->getMimeType(@_);
}

sub getNamedDispatcher {
    my $self = shift;

    return $self->{application}->getNamedDispatcher(@_);
}

sub getRealPath {
    my $self = shift;

    return $self->{application}->getRealPath(@_);
}

sub getRequestDispatcher {
    my $self = shift;

    return $self->{application}->getRequestDispatcher(@_);
}

sub getResource {
    my $self = shift;

    return $self->{application}->getResource(@_);
}

sub getResourceAsStream {
    my $self = shift;

    return $self->{application}->getResourceAsStream(@_);
}

sub getResourcePaths {
    my $self = shift;

    return $self->{application}->getResourcePaths(@_);
}

sub getServerInfo {
    my $self = shift;

    return $self->{application}->getServerInfo(@_);
}

sub getServletContextName {
    my $self = shift;

    return $self->{application}->getServletContextName(@_);
}

sub log {
    my $self = shift;

    return $self->{application}->log(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletContext>,
L<Wombat::Core::Application>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
