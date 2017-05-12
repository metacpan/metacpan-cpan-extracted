# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::EngineMapper;

=pod

=head1 NAME

Wombat::Core::EngineMapper - internal mapper base class

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of B<Wombat::Mapper> for a B<Wombat::Core::Engine>.

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

    unless ($container && $container->isa('Wombat::Core::Engine')) {
        my $msg = "setContainer: container is not Engine\n";
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

    my $engine = $self->getContainer();
    my $freq = $request->getRequest();

    # figure out the requested server name
    my $server = $freq->getServerName();
    unless ($server) {
        $server = $engine->getDefaultHost();
        $freq->setServerName($server);
    }

    return undef unless $server;
    $server = lc $server;

    # try direct match
    my $host = $engine->getChild($server);

    unless ($host) {
        # try aliases
        no warnings; # shut up "* matches null string many times"
        for my $child ($engine->getChildren()) {
            for my $alias ($child->getAliases()) {
                if ($server =~ /^$alias$/) {
                    $host = $child;
                    last;
                }
            }
            last if $host;
        }
    }

    unless ($host) {
        # try default host
        $host ||= $engine->getChild($engine->getDefaultHost());
    }

    return $host;
}

1;
__END__

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Container>,
L<Wombat::Engine>,
L<Wombat::Mapper>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
