use strict;
use warnings;
use utf8;

package Ukigumo::Constants;
use parent qw(Exporter);

our @EXPORT = qw(STATUS_SUCCESS STATUS_FAIL STATUS_NA STATUS_SKIP STATUS_PENDING
                 STATUS_TIMEOUT NOTIFIER_GITHUBSTATUSES NOTIFIER_IKACHAN);

use constant {
    STATUS_SUCCESS => 1,
    STATUS_FAIL    => 2,
    STATUS_NA      => 3,
    STATUS_SKIP    => 4,
    STATUS_PENDING => 5,
    STATUS_TIMEOUT => 6,

    NOTIFIER_GITHUBSTATUSES => 'Ukigumo::Client::Notify::GitHubStatuses',
    NOTIFIER_IKACHAN        => 'Ukigumo::Client::Notify::Ikachan',
};

1;
__END__

=head1 NAME

Ukigumo::Constants - constants for Ukigumo

=head1 DESCRIPTION

A module provides constants for L<Ukigumo>.

=head1 CONSTANTS

=over 4

=item STATUS_SUCCESS

=item STATUS_FAIL

=item STATUS_NA

=item STATUS_SKIP

There is no reason to run the test cases.
(e.g. There is no new commits)

=item STATUS_PENDING

Tests are in process.

=item STATUS_TIMEOUT

=item NOTIFIER_GITHUBSTATUSES

Notifier class name for GitHub Statuses.

=item NOTIFIER_IKACHAN

Notifier class name for Ikachan.

=back

