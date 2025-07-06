#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use Getopt::Long;

my $check_mode;
my $new_version;

GetOptions(
    'check'     => \$check_mode,
    'version=s' => \$new_version,
);

my @pm_files;
find(
    sub {
        return unless /\.pm$/ && -f $_;
        push @pm_files, $File::Find::name;
    },
    'lib'
);

die "No .pm files found under lib/\n" unless @pm_files;

my %version_map;

foreach my $file (@pm_files) {
    open my $fh, '<', $file or die "Cannot read $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my $original = $content;

    # Check current version format
    if ($content =~ /our\s+\$VERSION\s*=\s*(['"])([^'"]+)\1\s*;/) {
        $version_map{$2}++;
    } elsif ($content =~ /our\s+\$VERSION\s*=\s*.+?;/) {
        $version_map{'(indirect)'}++;
    } else {
        $version_map{'(missing)'}++;
    }

    next if $check_mode;

    if (defined $new_version) {
        my $new_line = "our \$VERSION = '$new_version';";
        # Replace whole line safely, even if RHS was a variable
        $content =~ s/our\s+\$VERSION\s*=.*?;/$new_line/;

        if ($content ne $original) {
            open my $out, '>', $file or die "Cannot write $file: $!";
            print $out $content;
            close $out;
            print "✅ Updated $file to version $new_version\n";
        }
    }
}

# Version summary
print "\n=== VERSION SUMMARY ===\n";
foreach my $ver (sort keys %version_map) {
    printf "Version: %-12s | Files: %d\n", $ver, $version_map{$ver};
}

if ($check_mode) {
    print "\nCheck complete. ";
    if (keys %version_map == 1 && !exists $version_map{'(indirect)'} && !exists $version_map{'(missing)'}) {
        print "✅ All files use version '$new_version'.\n";
    } else {
        print "⚠️ Inconsistent, indirect, or missing versions found.\n";
    }
}
