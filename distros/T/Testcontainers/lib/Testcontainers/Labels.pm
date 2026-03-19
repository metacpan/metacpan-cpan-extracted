package Testcontainers::Labels;
# ABSTRACT: Standard Testcontainers labels for Docker resources

use strict;
use warnings;
use Carp qw( croak );
use Exporter 'import';

our $VERSION = '0.001';

our @EXPORT_OK = qw(
    LABEL_BASE
    LABEL_LANG
    LABEL_VERSION
    LABEL_SESSION_ID
    LABEL_REAPER
    LABEL_RYUK
    LABEL_REAP
    default_labels
    merge_custom_labels
    session_id
);

our %EXPORT_TAGS = (
    constants => [qw(
        LABEL_BASE
        LABEL_LANG
        LABEL_VERSION
        LABEL_SESSION_ID
        LABEL_REAPER
        LABEL_RYUK
        LABEL_REAP
    )],
    all => \@EXPORT_OK,
);

=head1 SYNOPSIS

    use Testcontainers::Labels qw( default_labels merge_custom_labels session_id );

    # Generate a session ID for this test run
    my $sid = session_id();

    # Get the standard labels every container should carry
    my %labels = default_labels($sid);

    # Safely merge user labels (rejects org.testcontainers.* overrides)
    my %merged = merge_custom_labels(\%labels, { app => 'mytest' });

=head1 DESCRIPTION

Implements the Testcontainers label specification as defined by the reference
implementations (Go, Java).  Every container created by Testcontainers carries
a set of well-known labels that identify it as managed by the framework, enable
Ryuk cleanup, and record session metadata.

=head1 LABEL CONSTANTS

The following constants mirror the Go reference at
C<internal/core/labels.go>:

=over

=item C<LABEL_BASE> - C<org.testcontainers>

Marker label.  Always set to C<"true">.

=item C<LABEL_LANG> - C<org.testcontainers.lang>

Language of the client library.  Set to C<"perl">.

=item C<LABEL_VERSION> - C<org.testcontainers.version>

Version of the Testcontainers library.

=item C<LABEL_SESSION_ID> - C<org.testcontainers.sessionId>

A unique identifier tying resources to a single test session.  Used by Ryuk
to determine which resources to reap.

=item C<LABEL_REAPER> - C<org.testcontainers.reaper>

Labels the Ryuk container itself.

=item C<LABEL_RYUK> - C<org.testcontainers.ryuk>

Labels the Ryuk container itself (alternate key).

=item C<LABEL_REAP> - C<org.testcontainers.reap>

When set to C<"true">, signals that the resource should be reaped by Ryuk.

=back

=cut

use constant LABEL_BASE       => 'org.testcontainers';
use constant LABEL_LANG       => 'org.testcontainers.lang';
use constant LABEL_VERSION    => 'org.testcontainers.version';
use constant LABEL_SESSION_ID => 'org.testcontainers.sessionId';
use constant LABEL_REAPER     => 'org.testcontainers.reaper';
use constant LABEL_RYUK       => 'org.testcontainers.ryuk';
use constant LABEL_REAP       => 'org.testcontainers.reap';

# ---------------------------------------------------------------------------
# Session ID — generated once per process and reused.
# ---------------------------------------------------------------------------

my $_session_id;

sub session_id {
    return $_session_id if defined $_session_id;
    $_session_id = _generate_uuid_v4();
    return $_session_id;
}

=func session_id()

Returns a UUID v4 string that uniquely identifies the current test session.
Generated lazily on first call and cached for the lifetime of the process.

=cut

# ---------------------------------------------------------------------------
# default_labels($session_id)
# ---------------------------------------------------------------------------

sub default_labels {
    my ($sid) = @_;
    $sid //= session_id();

    my %labels = (
        LABEL_BASE       ,=> 'true',
        LABEL_LANG       ,=> 'perl',
        LABEL_VERSION    ,=> $Testcontainers::Labels::VERSION,
        LABEL_SESSION_ID ,=> $sid,
    );

    # Add reap label unless Ryuk is disabled
    unless ($ENV{TESTCONTAINERS_RYUK_DISABLED}) {
        $labels{ LABEL_REAP() } = 'true';
    }

    return %labels;
}

=func default_labels($session_id?)

Returns a hash of the standard labels that every Testcontainers-managed
container should carry.  If C<$session_id> is omitted the per-process
session ID is used automatically.

When the environment variable C<TESTCONTAINERS_RYUK_DISABLED> is set to a
true value, the C<org.testcontainers.reap> label is omitted.

=cut

# ---------------------------------------------------------------------------
# merge_custom_labels(\%defaults, \%custom)
# ---------------------------------------------------------------------------

sub merge_custom_labels {
    my ($defaults, $custom) = @_;
    $custom //= {};

    my %merged = %{$defaults};

    for my $key (keys %{$custom}) {
        if ($key =~ /^org\.testcontainers(?:\.|$)/) {
            croak "Custom label '$key' uses the reserved 'org.testcontainers' "
                . "prefix; built-in labels cannot be overridden";
        }
        $merged{$key} = $custom->{$key};
    }

    return %merged;
}

=func merge_custom_labels(\%defaults, \%custom)

Merges user-supplied labels into the defaults.  Croaks if any custom label
key starts with C<org.testcontainers> to prevent accidental overrides of the
well-known labels.

=cut

# ---------------------------------------------------------------------------
# Internal: lightweight UUID v4 generator (no external deps)
# ---------------------------------------------------------------------------

sub _generate_uuid_v4 {
    # 16 random bytes
    my @bytes = map { int(rand(256)) } 1 .. 16;

    # Set version 4 (bits 48-51)
    $bytes[6] = ($bytes[6] & 0x0f) | 0x40;

    # Set variant 10xx (bits 64-65)
    $bytes[8] = ($bytes[8] & 0x3f) | 0x80;

    return sprintf(
        '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x',
        @bytes,
    );
}

1;
