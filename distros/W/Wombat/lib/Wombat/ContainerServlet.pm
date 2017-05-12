# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::ContainerServlet;

$VERSION = 0;

1;

__END__

=pod

=head1 NAME

Wombat::ContainerServlet - internal container servlet interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a servlet that has access to Wombat internal
functionality. The accessor methods must be called by the Container
whenever a new instance of the servlet is put into service.

=head1 accessor METHODS

=over

=item getWrapper()

Return the Wrapper that wraps this Servlet.

=item setWrapper($wrapper)

Set the Wrapper that wraps this Servlet.

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Core::Wrapper> that wraps this Servlet

=back

=back

=head1 SEE ALSO

L<Servlet::Servlet>,
L<Wombat::Core::Wrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
