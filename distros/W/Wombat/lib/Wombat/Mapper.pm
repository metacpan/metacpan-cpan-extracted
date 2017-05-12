# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Mapper;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Mapper - internal mapper interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a component that selects a subordinate
Container to continue processing a Request for a parent Container,
modifying the properties of the Request to reflect the selections
made.

A Container may be associated with a single Mapper that processes all
requests to that Container or a Mapper for each request protocol that
the Container supports.

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container with which the Mapper is associated.

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

=item getProtocol()

Return the protocol for which this Mapper is responsible.

=item setProtocol($protocol)

Set the protocol for which this Mapper is responsible.

B<Parameters:>

=over

=item $protocol

the protocol

=back

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

=back

=head1 SEE ALSO

L<Wombat::Container>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
