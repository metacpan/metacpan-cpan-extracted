package ThreatDetector::Handlers::DirectoryTraversal;

use strict;
use warnings;
use Exporter 'import';
use JSON;
use Time::HiRes qw(gettimeofday);

our $VERBOSE = 0;
our @EXPORT_OK = qw(handle_directory_traversal get_directory_traversal_events);
our @DIRECTORY_TRAVERSAL_EVENTS;
our $VERSION = '0.04';

sub handle_directory_traversal {
    my ($entry) = @_;
    my ($sec, $micro) = gettimeofday();

    my $alert = {
        timestamp => "$sec.$micro",
        type => 'directory_traversal',
        ip => $entry->{ip},
        method => $entry->{method},
        uri => $entry->{uri},
        status => $entry->{status},
        user_agent => $entry->{user_agent},
    };
    push @DIRECTORY_TRAVERSAL_EVENTS, $alert;
    print encode_json($alert) . "\n" if $VERBOSE;
}

sub get_directory_traversal_events {
  return @DIRECTORY_TRAVERSAL_EVENTS;
}

1;


=head1 NAME

ThreatDetector::Handlers::DirectoryTraversal - Handler for directory traversal attempts

=head1 SYNOPSIS

  use ThreatDetector::Handlers::DirectoryTraversal qw(handle_directory_traversal);

  handle_directory_traversal($entry);

=head1 DESCRIPTION

Prints a JSON alert for requests containing suspected directory traversal patterns such as `../`, URL-encoded traversal attempts, or sensitive path access. These attacks aim to access unauthorized files outside the web root.

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut