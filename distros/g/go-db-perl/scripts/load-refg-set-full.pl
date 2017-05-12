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
    next if /^target_id/; # first line / headers
    my ($id,$sp,$acc,$symbol) = split(/\s*\t\s*/,$_);
    if ($id =~ /:/) {
    }
    else {
        $id = "OMIM:$id";
    }



    push(@{$gp_by_hset{$id}},$acc);
    $symbol =~ s/^\s+//;
    $symbol =~ s/\s+$//;
    $symbol_by_hset{$id} =$symbol; 
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

#$dbh->disconnect;
print STDERR "Done!\n";
exit 0;

sub usage() {
    print <<EOM;
load-refg-set-full.pl -d godbname -h dbhost refg_id_list.txt

The file refg_id_list.txt is available from:

    ftp://ftp.informatics.jax.org/pub/curatorwork/GODB

and is periodically updated.

The columns are:

- homology grouping DBXREF : of the form <dbname>:<acc> - for example, OMIM:12345
- species name (currently ignored by script)
- MOD dbxref : of the form <dbname>:<acc>. Entries of the form <acc> are still accepted
- homology grouping symbol/label

MOD dbxref is used to lookup gene_product by dbxref_id

homology dbxref is used to populate homomset.dbxref_id

EOM
}
