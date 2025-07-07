package ThreatDetector::Handlers::LoginBruteForce;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_login_bruteforce get_login_brute_force_events);
our @BRUTE_FORCE_EVENTS;
our $VERSION = '0.04';

sub handle_login_bruteforce {
    my ($entry) = @_;
    my ( $sec, $micro ) = gettimeofday();

    my $alert = {
        timestamp  => "$sec.$micro",
        type       => 'login_bruteforce',
        ip         => $entry->{ip},
        method     => $entry->{method},
        uri        => $entry->{uri},
        status     => $entry->{status},
        user_agent => $entry->{user_agent},
        referer    => $entry->{referer} || '',
    };
    push @BRUTE_FORCE_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_login_brute_force_events {
  return @BRUTE_FORCE_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::LoginBruteForce - Handler for login brute-force attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::LoginBruteForce qw(handle_login_bruteforce);

  handle_login_bruteforce($entry);

=head1 DESCRIPTION

Prints a JSON alert for suspected brute-force login attempts. Typically used in conjunction with logic that detects rapid repeated login attempts from the same IP or URI pattern (e.g., `/login`, `/admin`).

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
