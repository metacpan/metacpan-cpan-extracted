package ThreatDetector::Handlers::SQLInjection;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_sql_injection get_sqli_events);
our @SQLI_EVENTS;
our $VERSION = '0.04';

sub handle_sql_injection {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

     my $alert = {
        timestamp  => "$sec.$micro",
        type       => 'sql_injection',
        ip         => $entry->{ip},
        method     => $entry->{method},
        uri        => $entry->{uri},
        status     => $entry->{status},
        user_agent => $entry->{user_agent},
        referer    => $entry->{referer} || '',
    };

    push @SQLI_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_sqli_events {
  return @SQLI_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::SQLInjection - Handler for SQL injection attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::SQLInjection qw(handle_sql_injection);

  handle_sql_injection($entry);

=head1 DESCRIPTION

Emits a JSON-formatted alert when a request appears to contain SQL injection payloads. Common indicators include suspicious keywords (e.g., `SELECT`, `UNION`), tautologies, comment markers, or known SQLi functions.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut