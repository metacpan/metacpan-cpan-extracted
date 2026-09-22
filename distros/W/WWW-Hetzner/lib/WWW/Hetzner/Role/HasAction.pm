package WWW::Hetzner::Role::HasAction;
# ABSTRACT: Entity role exposing a creation action

our $VERSION = '0.101';

use Moo::Role;
use namespace::clean;


has action => ( is => 'ro' );


has next_actions => ( is => 'ro', default => sub { [] } );



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::HasAction - Entity role exposing a creation action

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package WWW::Hetzner::Cloud::Server;
    use Moo;
    with 'WWW::Hetzner::Role::HasAction';

    # after create()
    print $server->action->command, "\n";       # e.g. "create_server"
    print scalar @{ $server->next_actions }, "\n";

=head1 DESCRIPTION

Shared attributes for entities whose creation endpoint returns a singular
C<action> (and optionally C<next_actions>) alongside the resource itself.
The owning API controller populates them from its C<create> response; they are
not maintained afterwards.

=head2 action

The L<WWW::Hetzner::Action> returned by C<create>, or undef when the API did
not emit one. Reflects creation state only: the consuming entity's own
C<refresh> method, where it defines one, does not update it.

=head2 next_actions

Arrayref of L<WWW::Hetzner::Action> objects returned by C<create> as
C<next_actions>. Empty arrayref when the API did not emit any.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Role::HasActions> - Controller role wrapping raw hashes as Action objects

=item * L<WWW::Hetzner::Action> - Action entity class

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
