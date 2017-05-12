#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use Getopt::Long;

# Get args

my $apph = GO::AppHandle->connect(\@ARGV);

# names.dmp
# from NCBI Taxonomy ftp
my $fn = shift @ARGV;
my %binom = ();
my %common = ();
open(F, $fn) || die($fn);
while(<F>) {
    chomp;
    my ($id, $name, $name2, $type) = 
      map {s/^\s*//;s/\s*$//;$_ }
	split(/\|/, $_);
    
    next unless $type;
    if ($type eq 'scientific name') {
	$binom{$id} = $name2 || $name;
    }
    if ($type eq 'genbank common name') {
	$common{$id} = $name;
    }
}
close(F);
map {
    eval {
        $apph->store_species($_, $binom{$_}, $common{$_});
    };
    if ($@) {
        # may be some duplicate entries - eg
        # environmental samples
        # unidentified cyanobacterium
        print STDERR $@;
    }

} keys %binom;

print STDERR "Done!\n";
