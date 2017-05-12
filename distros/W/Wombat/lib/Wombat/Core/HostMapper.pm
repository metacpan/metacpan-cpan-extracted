# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::HostMapper;

=pod

=head1 NAME

Wombat::Core::HostMapper - core host mapper class

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of B<Wombat::Mapper> for a B<Wombat::Core::Host>.

=cut

use base qw(Wombat::Core::MapperBase);
use strict;
use warnings;

use Servlet::Util::Exception ();

=pod

=head1 ACCESSOR METHODS

=over

=item setContainer($container)

Set the Container with which the Mapper is associated.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> used for processing Requests

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the Container is not acceptable to this Mapper

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    unless ($container && $container->isa('Wombat::Core::Host')) {
        my $msg = "setContainer: container is not Host\n";
        Servlet::Util::IllegalArgumentException->throw($container);
    }

    $self->SUPER::setContainer($container);

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item map($request)

Return the child Container that should be used to process the
Request, or C<undef> f no such child Container can be identified.

B<Parameters:>

=over

=item $request

the B<Wombat::Request> being processed

=back

=cut

sub map {
    my $self = shift;
    my $request = shift;

    my $application = $request->getApplication();
    return $application if $application;

    my $freq = $request->getRequest();
    my $host = $self->getContainer();

    my $uri = $freq->getRequestURI();
    return undef unless $uri;

    # match the longest possible context path prefix
    while ($uri) {
        $application = $host->getChild($uri);
        last if $application;
        $uri =~ s|/[^/]*$||;
    }

    $request->setApplication($application);
    if ($application) {
        $request->setContextPath($application->getPath());
    } else {
        $request->setContextPath(undef);
    }

    return $application;
}

1;
__END__

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Container>,
L<Wombat::Host>,
L<Wombat::Mapper>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
