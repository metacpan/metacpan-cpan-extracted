package ThreatDetector::Handlers::MethodAbuse;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_http_method get_http_method_abuse_events);
our @HTTP_METHOD_EVENTS;
our $VERSION = '0.04';

sub handle_http_method {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp => "$sec.$micro",
        type => 'http_method_abuse',
        ip => $entry->{ip},
        method => $entry->{method},
        uri => $entry->{uri},
        status => $entry->{status},
        user_agent => $entry->{user_agent},
        referer => $entry->{referer} || '',
    };
    push @HTTP_METHOD_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_http_method_abuse_events {
  return @HTTP_METHOD_EVENTS;
}

1;


=head1 NAME

ThreatDetector::Handlers::MethodAbuse - Handler for abuse of uncommon or dangerous HTTP methods

=head1 SYNOPSIS

  use ThreatDetector::Handlers::MethodAbuse qw(handle_http_method);

  handle_http_method($entry);

=head1 DESCRIPTION

Prints a JSON alert when a request uses suspicious HTTP methods such as PUT, DELETE, TRACE, or CONNECT. These methods are rarely needed in normal web traffic and are often associated with probing or misuse.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut