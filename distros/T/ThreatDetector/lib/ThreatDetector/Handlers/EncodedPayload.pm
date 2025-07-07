package ThreatDetector::Handlers::EncodedPayload;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_encoded get_encoded_payload_events);
our @ENCODED_PAYLOAD_EVENTS;
our $VERSION = '0.04';

sub handle_encoded {
    my ($entry) = @_;
    my ( $sec, $micro ) = gettimeofday();

    my $alert = {
        timestamp  => "$sec.$micro",
        type       => 'encoded_payload',
        ip         => $entry->{ip},
        method     => $entry->{method},
        uri        => $entry->{uri},
        status     => $entry->{status},
        user_agent => $entry->{user_agent},
    };
    push @ENCODED_PAYLOAD_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_encoded_payload_events {
  return @ENCODED_PAYLOAD_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::EncodedPayload - Handler for encoded payload attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::EncodedPayload qw(handle_encoded);

  handle_encoded($entry);

=head1 DESCRIPTION

Prints a JSON alert for requests that contain suspiciously encoded characters (e.g. %2e, %3c) which may indicate obfuscated payloads or bypass attempts. Often a precursor to more serious attacks like XSS, path traversal, or command injection.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
