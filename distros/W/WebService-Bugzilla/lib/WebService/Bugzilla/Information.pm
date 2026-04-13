#!/usr/bin/false
# ABSTRACT: Bugzilla server information endpoints
# PODNAME: WebService::Bugzilla::Information

package WebService::Bugzilla::Information 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has server_extensions      => (is => 'ro', lazy => 1, builder => sub { shift->_simple_get('extensions') });
has server_jobqueue_status => (is => 'ro', lazy => 1, builder => sub { shift->_simple_get('jobqueue_status') });
has server_time            => (is => 'ro', lazy => 1, builder => sub { shift->_simple_get('time') });
has server_timezones       => (is => 'ro', lazy => 1, builder => sub { shift->_simple_get('timezones') });
has server_version         => (is => 'ro', lazy => 1, builder => sub { shift->_simple_get('version') });

sub refresh {
    my ($self) = @_;
    delete $self->{$_} for qw(server_extensions server_jobqueue_status server_time server_timezones server_version);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Information - Bugzilla server information endpoints

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $info = $bz->information;
    say 'Server version: ', $info->server_version;
    say 'Server time:    ', $info->server_time;

    $info->refresh;  # clear cached values
    say 'Updated time:   ', $info->server_time;

=head1 DESCRIPTION

Provides access to server metadata endpoints such as the Bugzilla version,
installed extensions, time, and time-zone information.  Useful for debugging
or integration health checks.

=head1 ATTRIBUTES

All attributes are read-only and lazy.  Each fetches its value from the
server on first access.  Call L</refresh> to clear cached values.

=over 4

=item C<server_extensions>

Hashref of installed Bugzilla extensions and their versions.

=item C<server_jobqueue_status>

Job queue status information.

=item C<server_time>

Current server time (ISO 8601 string).

=item C<server_timezones>

List of time zones known to the server.

=item C<server_version>

Bugzilla version string reported by the server.

=back

=head1 METHODS

=head2 refresh

    $info->refresh;

Clear all cached attribute values so that the next access re-fetches
fresh data from the server.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
