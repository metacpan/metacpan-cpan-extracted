package ThreatDetector::Parser;

use strict;
use warnings;
use URI::Escape;

our $VERBOSE = 0;
our $VERSION = '0.04';

our %STATS = (
    parsed  => 0,
    skipped => 0,
);

sub parse_log_line {
    my ($line) = @_;
    $line =~ s/\r//g;

    warn ">> parse_log_line() called with: [$line]\n" if $VERBOSE;

# Common Log Format (with or without referer + user-agent)
# Example:
# 192.168.0.1 - - [20/Jun/2025:13:55:36 -0700] "GET /index.php?id=1 HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
    if (
        $line =~ m/^
        (\d{1,3}(?:\.\d{1,3}){3})          # IP
        \s+ \S+ \s+ \S+                    # - - (unused)
        \s+ \[([^\]]+)\]                   # [timestamp]
        \s+ "(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH)
        \s+ ([^"]+?)                       # URI
        \s+ HTTP\/[0-9.]+"                 # Protocol
        \s+ (\d{3})                        # Status
        \s+ (\d+|-)                        # Size
        \s+ "([^"]*)"                      # Referer
        \s+ "([^"]*)"                      # User-Agent
    /x
      )
    {
        my ( $ip, $time, $method, $uri, $status, $size, $referer, $agent ) =
          ( $1, $2, $3, uri_unescape($4), $5, $6, $7, $8 );

        $STATS{parsed}++;
        return {
            ip         => $ip,
            time       => $time,
            method     => $method,
            uri        => $uri,
            status     => $status,
            size       => $size,
            referer    => $referer,
            user_agent => $agent,
            raw        => $line,
        };
    }
    $STATS{skipped}++;
    return undef;
}

1;

=head1 NAME

ThreatDetector::Parser - Apache log parser for threat detection

=head1 SYNOPSIS

  use ThreatDetector::Parser;
  my $entry = ThreatDetector::Parser::parse_log_line($line);

=head1 DESCRIPTION

Parses lines from an Apache access log and extracts structured request info.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
