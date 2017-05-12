#!/usr/bin/perl -w

use strict;
use WWW::Rapidshare::Free qw( :all );

# Make verbose true for a fancy delay metre and progress bar. ;-)
# Else, handle on our own with the callbacks.
verbose(0);

print "Enter the following commands:\n";
print "Connect command: ";
chomp( my $connect = <STDIN> );
print "Disconnect command: ";
chomp( my $disconnect = <STDIN> );

my @links = add_links(
    'http://rapidshare.com/files/175658683/perl-51.zip',
    'http://rapidshare.com/files/1234567890/perl-51.zip',    # Invalid link
    'http://rapidshare.com/files/175662062/perl-52.zip',
    '#http://rapidshare.com/files/175662703/perl-53.zip',    # Commented link
    'htpp/rapidshare.com/files/1234567890/perl-54.zip',      # Erroneous link
);
print "Added links:\n";
map print("\t$_\n"), @links;
print "Erroneous links:\n";
my @erroneous_links = check_links;
map {
    my ( $uri, $error ) = @{$_};
    print "\tURI: $uri\n\tError: $error\n";
} @erroneous_links;
download(
    delay         => \&delay,
    properties    => \&properties,
    progress      => \&progress,
    file_complete => \&file_complete,
);

sub delay {
    my $delay = shift;
    printf "\rDelay: %3d seconds", $delay;
}

my $file_size;

sub properties {
    my $file_name = shift;
    $file_size = shift;
    print "\rFilename: $file_name\nFile size: $file_size bytes\n";
}

sub progress {
    my $output = shift;

    # A very simple progress indicator
    print "\r$output / $file_size";
}

sub file_complete {    # Connection called inside the callback
    print "\nFile downloaded successfully!\n";    # Most probably!
    connection(
        connect    => $connect,                 # Example: sudo pppoe-start
        disconnect => $disconnect,              # Example: sudo pppoe-stop
    );
}
