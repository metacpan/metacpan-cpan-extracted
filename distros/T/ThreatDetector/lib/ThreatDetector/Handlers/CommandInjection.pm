package ThreatDetector::Handlers::CommandInjection;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_command_injection get_command_injection_events);
our @COMMAND_INJECTION_EVENTS;
our $VERSION = '0.04';

sub handle_command_injection {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp => "$sec.$micro",
        type => 'command_injection',
        ip => $entry->{ip},
        method => $entry->{method},
        uri => $entry->{uri},
        status => $entry->{status},
        user_agent => $entry->{user_agent},
    };
    push @COMMAND_INJECTION_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_command_injection_events {
  return @COMMAND_INJECTION_EVENTS;
}

1;

=head1 NAME

ThreatDetector::Handlers::CommandInjection - Handler for command injection/RFI/LFI attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::CommandInjection qw(handle_command_injection);

  handle_command_injection($entry);

=head1 DESCRIPTION

Prints a JSON alert for requests that appear to contain command injection or remote/local file inclusion attempts. These are serious indicators of active exploitation attempts.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut