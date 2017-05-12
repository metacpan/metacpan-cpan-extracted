#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use Perl6::Slurp qw(slurp);
use WebService::Ares::Standard qw(parse);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 xml_file\n";
        exit 1;
}
my $xml_file = $ARGV[0];

# Get XML.
my $xml = slurp($xml_file);

# Parse.
my $data_hr = parse($xml);

# Print.
p $data_hr;

# Output like:
# Usage: /tmp/WfgYq5ttuP xml_file