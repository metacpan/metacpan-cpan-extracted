package Test::FitNesse::Slim;

use strict;
use warnings;

our $VERSION = '1.00';

1;

=head1 NAME

Test::FitNesse::Slim - Perl implementation of the FitNesse SLiM protocol

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

C<Test::FitNesse::Slim> implements the server side of FitNesse's Simple List
Invocation Method (SLiM) protocol. This package provides the distribution
version and documentation; it does not expose a constructor or exported
function API.

L<Test::FitNesse::Slim::Server> processes framed requests, executes fixture
instructions, and writes responses. The C<perl-slim> executable is the
normal way to start the server.

=head1 SYNOPSIS

Start the v0.5 stdin/stdout transport as a FitNesse-managed child process:

    perl-slim 1

Start a TCP listener on port 8099:

    perl-slim 8099

For pipe transport, configure FitNesse with C<COMMAND_PATTERN=%m>,
C<TEST_RUNNER> set to the installed executable, and C<SLIM_PORT=1>. For TCP,
configure the FitNesse SLiM service to connect to the listener's host and
port. See C<docs/slim-pipe-transport.md> and
C<docs/fitnesse-cli-runner-configuration.md> for complete examples.

Fixture authors declare conversion metadata with C<slim_method_signature>
and C<slim_constructor_signature>. See C<docs/fixture-conversion.md> for
supported types and a runnable fixture example.

=head1 SUPPORT

The project repository is at L<https://github.com/gbacon/test-slim>. Report
bugs and compatibility findings through the project's issue tracker.

=head1 AUTHOR

Greg Bacon, C<< <gbacon@gbacon.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2026 Greg Bacon.

This program is free software; you can redistribute it and/or modify it
under the terms of either the GNU General Public License, version 1 or any
later version, or the Artistic License 1.0. The test-only FitNesse fixture
adaptations listed in C<THIRD-PARTY-NOTICES.md> are separately licensed under
the Common Public License 1.0. See the included license files for details.

=cut
