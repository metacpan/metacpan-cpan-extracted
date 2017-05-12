# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::ApplicationMapper;

=pod

=head1 NAME

Wombat::Core::ApplicationMapper - core application mapper class

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of B<Wombat::Mapper> for a B<Wombat::Core::Application>.

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

    unless ($container && $container->isa('Wombat::Core::Application')) {
        my $msg = "setContainer: container is not Application\n";
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

    my $wrapper = $request->getWrapper();
    return $wrapper if $wrapper;

    my $freq = $request->getRequest();
    my $application = $self->getContainer();

    # identify the context-relative uri to be mapped
    my $contextPath = $freq->getContextPath();
    my $requestURI = $freq->getRequestURI();

    (my $relativeURI = $requestURI) =~ s|^$contextPath||;
    $relativeURI = URI::Escape::uri_unescape($relativeURI);

    my $servletPath;
    my $pathInfo;
    my $name;

    # check for exact match
    unless ($wrapper) {
        $name = $application->getServletMapping($relativeURI);
        if ($name) {
            $wrapper = $application->getChild($name);
            if ($wrapper) {
                $servletPath = $relativeURI;
                $pathInfo = undef;
            }
        }
    }

    # check for path prefix matching
    unless ($wrapper) {
        $servletPath = $relativeURI;
        while ($servletPath) {
            $name = $application->getServletMapping("$servletPath/*");
            if ($name) {
                $wrapper = $application->getChild($name);
                if ($wrapper) {
                    ($pathInfo = $relativeURI) =~ s|^$servletPath||;
                    $pathInfo ||= undef;
                    last;
                }
            }
            $servletPath =~ s|/[^/]*$||;
        }
    }

    # check for suffix matching
    unless ($wrapper) {
        my ($ext) = ($relativeURI =~ m|\.([^.]+)$|);
        if ($ext) {
            my $pattern = "*.$ext";
            $name = $application->getServletMapping($pattern);
            if ($name) {
                $wrapper = $application->getChild($name);
                if ($wrapper) {
                    $servletPath = $relativeURI;
                    $pathInfo = undef;
                }
            }
        }
    }

    # check for default matching
    unless ($wrapper) {
        $name = $application->getServletMapping('/');
        if ($name) {
            $wrapper = $application->getChild($name);
            if ($wrapper) {
                $servletPath = $relativeURI;
                $pathInfo = undef;
            }
        }
    }

    $request->setWrapper($wrapper);
    $request->setServletPath($servletPath);
    $request->setPathInfo($pathInfo);

    return $wrapper;
}

1;
__END__

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Application>,
L<Wombat::Container>,
L<Wombat::Mapper>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
