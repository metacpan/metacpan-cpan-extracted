package WWW::Hetzner::Action;
# ABSTRACT: Hetzner API action object

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has poll_path => ( is => 'ro', default => sub { '/actions' } );


has id => ( is => 'ro' );


has command => ( is => 'ro' );


has status => ( is => 'rwp' );


has progress => ( is => 'rwp' );


has started => ( is => 'ro' );


has finished => ( is => 'ro' );


has resources => ( is => 'ro', default => sub { [] } );


has error => ( is => 'rwp' );


has result => ( is => 'ro', default => sub { {} } );


sub root_password { shift->result->{root_password} }


sub image { shift->result->{image} }


sub wss_url { shift->result->{wss_url} }


sub password { shift->result->{password} }


sub is_running { shift->status eq 'running' }


sub is_success { shift->status eq 'success' }


sub is_error { shift->status eq 'error' }


sub error_message {
    my ($self) = @_;
    my $error = $self->error;
    return ref $error ? $error->{message} : undef;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh action without ID" unless $self->id;

    my $result = $self->_client->get($self->poll_path . '/' . $self->id);
    my $data = $result->{action};

    $self->_set_status($data->{status});
    $self->_set_progress($data->{progress});
    $self->_set_error($data->{error});

    return $self;
}


sub wait {
    my ($self, %opts) = @_;
    my $interval = $opts{interval} // 1;
    my $timeout  = $opts{timeout}  // 120;

    my $waited = 0;
    while ($self->is_running) {
        croak sprintf('Timed out waiting for action %s (%s)', $self->id, $self->command)
            if $waited >= $timeout;

        $self->_client->sleeper->($interval);
        $waited += $interval;
        $self->refresh;
    }

    croak sprintf('Action %s (%s) failed: %s',
        $self->id, $self->command, $self->error_message // 'unknown')
        if $self->is_error;

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id        => $self->id,
        command   => $self->command,
        status    => $self->status,
        progress  => $self->progress,
        started   => $self->started,
        finished  => $self->finished,
        resources => $self->resources,
        error     => $self->error,
    };
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Action - Hetzner API action object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $action = $cloud->actions->get($id);

    # Read attributes
    print $action->id, "\n";
    print $action->command, "\n";
    print $action->status, "\n";

    # Check status
    if ($action->is_running) { ... }
    if ($action->is_success) { ... }
    if ($action->is_error)   { ... }

    # Poll once
    $action->refresh;

    # Block until terminal
    $action->wait(interval => 2, timeout => 120);

=head1 DESCRIPTION

This class represents an asynchronous Hetzner API action, the job object returned
by resource-mutating calls (create, delete, power actions, ...). Objects are
returned by API-controller methods that expose actions.

=head2 poll_path

Base path used by L</refresh> to reload this action (read-only).

=head2 id

Action ID (read-only).

=head2 command

Action command, e.g. "create_server" (read-only).

=head2 status

Action status: running, success, error (read-only).

=head2 progress

Progress percentage, 0-100 (read-only).

=head2 started

Timestamp the action started (read-only).

=head2 finished

Timestamp the action finished, or undef while running (read-only).

=head2 resources

Arrayref of resources this action refers to (read-only).

=head2 error

Error hashref (C<{ code, message }>) when the action failed, else undef
(read-only).

=head2 result

Hashref (default C<{}>) of sidecar fields some endpoints return alongside
C<action>. See L</root_password>, L</image>, L</wss_url>, and L</password>
for typed readers over this hash (read-only).

=head2 root_password

    my $pw = $action->root_password;

Convenience reader for C<< $action->result->{root_password} >>. Undef when
absent.

=head2 image

    my $image_id = $action->image;

Convenience reader for C<< $action->result->{image} >>. Undef when absent.

=head2 wss_url

    my $url = $action->wss_url;

Convenience reader for C<< $action->result->{wss_url} >>. Undef when absent.

=head2 password

    my $pw = $action->password;

Convenience reader for C<< $action->result->{password} >>. Undef when
absent.

=head2 is_running

    if ($action->is_running) { ... }

Returns true if action status is "running".

=head2 is_success

    if ($action->is_success) { ... }

Returns true if action status is "success".

=head2 is_error

    if ($action->is_error) { ... }

Returns true if action status is "error".

=head2 error_message

    my $message = $action->error_message;

Returns C<error.message> when the action failed, else undef.

=head2 refresh

    $action->refresh;

Reloads status/progress/error from the API via C<GET $poll_path/$id>.

=head2 wait

    $action->wait(interval => 2, timeout => 120);

Polls (via L</refresh>) until the action reaches a terminal status,
sleeping C<interval> seconds between polls via the client's C<sleeper>.
Returns C<$self> on success. Croaks with the API C<error.message> if the
action fails, and with the action's id and command if C<timeout> is
reached before the action finishes. Does not sleep when the action is
already terminal.

=head2 data

    my $hashref = $action->data;

Returns all action data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Role::HasAction> - Entity role exposing a creation action

=item * L<WWW::Hetzner::Role::HasActions> - Controller role wrapping actions

=item * L<WWW::Hetzner> - Main umbrella module

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
