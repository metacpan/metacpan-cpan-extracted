package ThreatDetector::Handlers::BotFingerprint;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_scanner get_scanner_fingerprint_events);
our @SCANNER_FINGERPRINT_EVENTS;
our $VERSION = '0.04';

sub handle_scanner {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp => "$sec.$micro",
        type => 'scanner_fingerprint',
        ip => $entry->{ip},
        method => $entry->{method},
        uri => $entry->{uri},
        status => $entry->{status},
        user_agent => $entry->{user_agent},
    };
    push @SCANNER_FINGERPRINT_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_scanner_fingerprint_events {
  return @SCANNER_FINGERPRINT_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::BotFingerprint - Handler for scanner and bot user-agent matches

=head1 SYNOPSIS

  use ThreatDetector::Handlers::BotFingerprint qw(handle_scanner);

  handle_scanner($entry);

=head1 DESCRIPTION

Prints a JSON alert for any request that matches a known bad scanner or bot fingerprint in the user-agent string.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut