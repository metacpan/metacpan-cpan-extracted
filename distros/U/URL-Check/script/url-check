#!/usr/bin/perl

use strict; use warnings;
use URL::Check;
use Getopt::Long;

my ($config, $help);
GetOptions(
    "config=s" => \$config,
    "help"     => \$help
) || help_message();

help_message() if ($help);

URL::Check::readConfig($config);
URL::Check::run();

my %report = URL::Check::errorReport();
if (%report) {
    URL::Check::submitReport(%report);
}

sub help_message {
    print "$0 --config=/path/to/config.txt\n\n";
    exit 1;
};
