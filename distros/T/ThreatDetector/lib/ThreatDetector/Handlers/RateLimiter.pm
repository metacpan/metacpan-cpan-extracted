package ThreatDetector::Handlers::RateLimiter;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_rate_burst get_rate_burst_events);
our @RATE_BURST_EVENTS;
our $VERSION = '0.04';

my %ip_activity;

my $TIME_WINDOW = 10;
my $MAX_REQUESTS = 20;

sub handle_rate_burst {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();
    my $now = $sec + ($micro / 1_000_000);
    my $ip = $entry->{ip};

    push @{ $ip_activity{$ip} }, $now;

    @{ $ip_activity{$ip} } = grep { $_ >= $now - $TIME_WINDOW } @{ $ip_activity{$ip} };

    if (@{ $ip_activity{$ip} } > $MAX_REQUESTS) {
        my $alert = {
            timestamp => "$sec.$micro",
            type => 'rate_burst',
            ip => $ip,
            count => scalar @{ $ip_activity{$ip} },
            method => $entry->{method},
            uri => $entry->{uri},
            status => $entry->{status},
            user_agent => $entry->{user_agent},
            referer => $entry->{referer} || '',
        };
        push @RATE_BURST_EVENTS, $alert;
        print encode_json($alert) . "\n" if $VERBOSE;
        $ip_activity{$ip} = [];
    }
}

sub get_rate_burst_events {
    return @RATE_BURST_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::RateLimiter - Detects rate-based abuse by tracking burst activity

=head1 SYNOPSIS

  use ThreatDetector::Handlers::RateLimiter qw(handle_rate_burst);

  handle_rate_burst($entry);

=head1 DESCRIPTION

Monitors how frequently a given IP sends requests. If the number of requests in a short time window exceeds a configured threshold, it emits an alert. This is useful for detecting denial-of-service attempts, scraping bots, or brute-force login attempts spread across different endpoints.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut