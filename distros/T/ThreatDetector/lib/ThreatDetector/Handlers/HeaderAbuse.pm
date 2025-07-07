package ThreatDetector::Handlers::HeaderAbuse;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_header_abuse get_header_abuse_events);
our @HEADER_ABUSE_EVENTS;
our $VERSION = '0.04';

sub handle_header_abuse {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp => "$sec.$micro",
        type => 'header_abuse',
        ip => $entry->{ip},
        method => $entry->{method},
        uri => $entry->{uri},
        status => $entry->{status},
        user_agent => $entry->{user_agent},
        referer => $entry->{referer} || '',
    };
    push @HEADER_ABUSE_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_header_abuse_events {
  return @HEADER_ABUSE_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::HeaderAbuse - Handler for suspicious or abusive HTTP headers

=head1 SYNOPSIS

  use ThreatDetector::Handlers::HeaderAbuse qw(handle_header_abuse);

  handle_header_abuse($entry);

=head1 DESCRIPTION

Prints a JSON alert when a log entry contains suspicious or abusive header values — typically malformed, spoofed, empty, or disallowed User-Agent or Referer headers. This can be indicative of scraping tools, fuzzers, or manual tampering.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut