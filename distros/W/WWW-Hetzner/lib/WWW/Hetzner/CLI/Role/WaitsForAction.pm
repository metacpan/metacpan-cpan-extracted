package WWW::Hetzner::CLI::Role::WaitsForAction;
# ABSTRACT: CLI role that waits for a returned Action by default

our $VERSION = '0.101';

use Moo::Role;
use MooX::Options;
use Scalar::Util qw(blessed);


option wait => (
    is          => 'ro',
    default     => 1,
    negativable => 1,
    doc         => 'wait for the action to reach a terminal state before returning',
);



sub no_wait { return $_[0]->wait ? 0 : 1 }


sub handle_action {
    my ($self, $action) = @_;
    return unless $action;

    if (ref $action eq 'ARRAY') {
        return if $self->no_wait;
        for my $a (@$action) {
            $a->wait if blessed($a) && $a->can('wait');
        }
        return $action;
    }

    return unless blessed($action) && $action->can('wait');
    return if $self->no_wait;
    $action->wait;
    return $action;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Role::WaitsForAction - CLI role that waits for a returned Action by default

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweron;
    use Moo;
    use MooX::Cmd;
    use MooX::Options protect_argv => 0;
    with 'WWW::Hetzner::CLI::Role::WaitsForAction';

    sub execute {
        my ($self, $args, $chain) = @_;
        my $action = $chain->[0]->cloud->servers->power_on($args->[0]);
        $self->handle_action($action);
        print $self->no_wait ? "Power-on requested.\n" : "Server powered on.\n";
    }

=head1 DESCRIPTION

Shared behaviour for CLI subcommands whose controller call returns a
L<WWW::Hetzner::Action> (or an arrayref of them, as Firewall's plural
methods do): wait for it to reach a terminal state before the command
reports success, unless the user opted out with C<--no-wait>.

Adds the C<--no-wait> command line flag (via L<MooX::Options>, so it is
usable from any consuming class that itself C<use>s C<MooX::Options>) and
L</handle_action>, the single point subcommands call after a mutating
controller method returns.

=head2 wait

Boolean, defaults to true. Exposed on the command line as C<--wait> /
C<--no-wait> (declared C<negativable> so L<MooX::Options> generates both
forms from this one attribute -- an attribute literally named C<no_wait>
would collide with L<MooX::Options>'s own C<no-> negation parsing and the
C<--no-wait> flag would never reach it). Command code should not need to
read this directly; use L</no_wait> or L</handle_action> instead.

=head2 no_wait

    $self->no_wait   # true when --no-wait was passed

The logical inverse of L</wait>, kept because it reads naturally at call
sites and matches the flag's name.

=head2 handle_action

    $self->handle_action($action);   # a single WWW::Hetzner::Action
    $self->handle_action($actions);  # an arrayref of them (Firewall plural methods)

Waits for C<$action> to reach a terminal state, unless C<--no-wait> was
given. Returns immediately, without waiting, when C<$action> is undef or
not something with a C<wait> method (an entity whose creation emitted no
action, e.g. an unmanaged placement group) and when C<--no-wait> is set.
An arrayref is handled element-wise: each waitable element is waited on in
turn, in order, so a rule/target/service action list all reach a terminal
state before the command reports completion.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Action> - Action entity class, provides C<wait>

=item * L<WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweron> - reference consumer

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
