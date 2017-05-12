#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use GO::SqlWrapper qw(:all);
use Getopt::Long;

# Get args

my $apph = GO::AppHandle->connect(\@ARGV);

my $subset = "reference_genome";
my @bad = ();
my $num_loaded = 0;
while (<>) {
    chomp;
    my ($id,$sp,$acc) = split(/\t/,$_);
    my $ok = $apph->add_product_to_subset($acc,$subset);
    if (!$ok) {
        push(@bad,$acc);
    }
    else {
        $num_loaded++;
    }
}

print STDERR "NOT_FOUND: $_\n" foreach @bad;
print STDERR "LOADED: $num_loaded\n";

#$dbh->disconnect;
print STDERR "Done!\n";
exit 0;

