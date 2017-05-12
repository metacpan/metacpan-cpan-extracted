#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use GO::SqlWrapper qw(:all);
use Getopt::Long;

# Get args

if ($ARGV[0] && $ARGV[0] eq '-help') {
    &usage();
    exit 0;
}

my $apph = GO::AppHandle->connect(\@ARGV);

my @bad = ();
my $num_loaded = 0;
my %gp_by_hset = ();
my %symbol_by_hset = ();
while (<>) {
    chomp;
    s/\r$//;  # remove PC carriage returns
    next if /^\!/;
    next if /^family/; # first line / headers
    my ($id,@accs) = split(/\s*\t\s*/,$_);
    my $symbol = $id;
    if ($id =~ /:/) {
    }
    else {
        $id = "PPOD:$id";
    }
    foreach my $acc (@accs) {
        $acc =~ s/\|.*//;
        push(@{$gp_by_hset{$id}},$acc);
        $symbol =~ s/^\s+//;
        $symbol =~ s/\s+$//;
        $symbol_by_hset{$id} =$symbol; 
    }
}
foreach my $hset (keys %gp_by_hset) {
    my $ok = $apph->add_homolset($hset,$symbol_by_hset{$hset},$gp_by_hset{$hset});
    if (!$ok) {
        push(@bad,$hset);
    }
    else {
        $num_loaded++;
    }
}

print STDERR "NOT_FOUND: $_\n" foreach @bad;
print STDERR "LOADED: $num_loaded\n";

print STDERR "Done!\n";
exit 0;

sub usage() {
    print <<EOM;
load-ppod-set-full.pl -d godbname -h dbhost GO0-families.tsv

The file is available from:

    ftp://gen-ftp.princeton.edu/ppod/go_ref_genome/orthomcl_results/GO0-families.tsv.gz

and is periodically updated.

EOM
}
