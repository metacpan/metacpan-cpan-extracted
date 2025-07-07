package ThreatDetector::Handlers::XSS;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_xss get_xss_events);
our @XSS_EVENTS;
our $VERSION = '0.04';

sub handle_xss {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp  => "$sec.$micro",
        type       => 'xss_attempt',
        ip         => $entry->{ip},
        method     => $entry->{method},
        uri        => $entry->{uri},
        status     => $entry->{status},
        user_agent => $entry->{user_agent},
        referer    => $entry->{referer} || '',
    };

    push @XSS_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_xss_events {
  return @XSS_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::XSS - Handler for cross-site scripting (XSS) attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::XSS qw(handle_xss);

  handle_xss($entry);

=head1 DESCRIPTION

Emits a JSON alert when a log entry indicates a potential cross-site scripting (XSS) attack based on common payload patterns such as `<script>`, event handler attributes (e.g. `onerror=`), or encoded equivalents. XSS can be used to hijack sessions, redirect users, or exfiltrate data.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
