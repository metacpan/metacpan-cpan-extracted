#!/usr/bin/perl

use strict;
use warnings;

use MIME::Base64 qw(decode_base64);
use Date::Parse qw(str2time);
use POSIX qw(strftime);
use ZipTie::Client;

my $host = shift(@ARGV);
my $client = ZipTie::Client->new(username => 'admin', password => 'password', host => $host . ':8080', );

my $configstore = $client->configstore();

my $op = shift(@ARGV) or usage();
my $device = shift(@ARGV) or die("Must specify a device\n");

my ($ip, $net) = split('@', $device);

if ($op eq 'history')
{
    my @change_logs = $configstore->retrieveChangeLog(ipAddress => $ip, managedNetwork => $net);
    show_change_log(@change_logs);
}
elsif ($op eq 'current')
{
    my @revs = $configstore->retrieveCurrentRevisionInfo(ipAddress => $ip, managedNetwork => $net);
    show_current_revs(@revs);
}
elsif ($op eq 'file')
{
    my $file = shift(@ARGV) or die("Must specify a file.\n");
    
    my $date = shift(@ARGV);

    $date = $date ? strftime("%Y-%m-%dT%H:%M:%S", localtime(str2time($date))) : undef;

    # add a preceeding slash if there isn't already one.
    $file =~ s|^([^/])|/$1|;

    my $rev = $configstore->retrieveRevision(ipAddress => $ip, managedNetwork => $net, configPath => $file, timestamp => $date);
    print(decode_base64($rev->{content}));
}
else
{
    usage();
}

sub usage
{
    print("Usage: config.pl <operation> [parameter ...]\n");
    print("   config.pl history <device>\n");
    print("   config.pl current <device>\n");
    print("   config.pl file <device> <path> [timestamp]\n");
    print("\n");
    print("Operations\n");
    print("  history - Shows the configuration history for the given device.\n");
    print("  current - Shows the current configurations for the given device.\n");
    print("  file    - Gets the contents for the specified revision.\n");
    print("\n");
    print("Parameters:\n");
    print("  device    - The IP address and managed network in the form of  '10.100.22.6\@Default'\n");
    print("              The managed network is optional.\n");
    print("  path      - The configuration path (ie: '/running-config').\n");
    print("              The slash prefix is optional.\n");
    print("  timestamp - A timestamp recognizable by perl's Date::Parse module.\n");
    exit(1);
}

sub show_current_revs
{
    my (@revs) = @_;

    printf("+-------------------------------------------------------------------------------+\n");
    printf("| %-30s | %8s | %-20s | %-10s |\n", 'Configuration', 'Size (B)', 'Last Modified', 'Mime-Type');
    printf("+--------------------------------+----------+----------------------+------------+\n");

    foreach (@revs)
    {
        my %rev = %$_;

        my $changed = strftime("%b %e %H:%M:%S %Y", localtime(str2time($rev{lastChanged})));
        my $type = $rev{mimeType};
        my $path = $rev{path};
        my $size = $rev{size};

        printf("| %-30s | %8d | %-20s | %-10s |\n", $path, $size, $changed, $type);
    }
    printf("+-------------------------------------------------------------------------------+\n");
}

sub show_change_log
{
    my (@change_logs) = @_;

    printf("+-----------------------------------------------------------------------------+\n");
    printf("| %-6s | %-30s | %-20s | %-10s |\n", 'Action', 'Configuration', 'Timestamp', 'Mime-Type');
    printf("+--------+--------------------------------+----------------------+------------+\n");
    foreach (@change_logs)
    {
        my %log = %$_;

        my $changes = $log{changes};
        my $tstamp = strftime("%b %e %H:%M:%S %Y", localtime(str2time($log{timestamp})));
        my $author = $log{author};

        foreach my $c (@$changes)
        {
            my $action = chr($c->{type});
            my $type = $c->{mimeType};
            my $path = $c->{path};

            $action = 'Update' if ($action eq 'M');
            $action = 'Add' if ($action eq 'A');
            $action = 'Remove' if ($action eq 'D');

            printf("| %-6s | %-30s | %-20s | %-10s |\n", $action, $path, $tstamp, $type);
        }
    }
    printf("+-----------------------------------------------------------------------------+\n");    
}
