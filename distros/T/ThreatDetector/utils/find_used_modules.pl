#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use Module::CoreList;

# Modules to ignore even if they show up in use/require
my %skip = map { $_ => 1 } qw(
    strict warnings utf8 open feature mro base parent
    vars constant Carp Exporter overload
);

# Project root
my $project_dir = '.';
my %modules;

find(
    {
        wanted => sub {
            return unless /\.(pl|pm|t)$/i;
            open my $fh, '<', $_ or do {
                warn "Could not open $_: $!";
                return;
            };

            while (<$fh>) {
                if (/^\s*(?:use|require)\s+([A-Za-z0-9_:]+)/) {
                    my $mod = $1;
                    next if $skip{$mod};
                    next if $mod =~ /^ThreatDetector::/;

                    $modules{$mod} = 1;
                }
            }

            close $fh;
        },
        no_chdir => 1,
    },
    $project_dir
);

# Current Perl version
my $perl_version = $];

# Filter out core modules
my @needed = grep {
    !Module::CoreList::is_core($_, undef, $perl_version)
} sort keys %modules;

# Output as PREREQ_PM hash
print "PREREQ_PM => {\n";
for my $mod (@needed) {
    print "    '$mod' => 0,\n";
}
print "},\n";
