#!/usr/bin/perl

use strict;
use warnings;
use lib "./lib";
use Test::More tests => 9;

BEGIN {
  use_ok ('Tie::File::AnyData::Bio::Fasta');
}

my $fafile = "t/Data/ex2.fa";
tie my @arr, 'Tie::File::AnyData::Bio::Fasta',$fafile;
ok (@arr == 301, "OK number of sequences");

## Creamos un archivo:
my $fanew = "t/Data/exnew.fa";
tie my @newfa, 'Tie::File::AnyData::Bio::Fasta',$fanew;
@newfa = reverse @arr;
ok (@newfa == 301, "OK number of fasta seqs in created file");
ok (@arr   == 301, "OK the original file untouched");

my $faseq = ">testfa\nAGCCGAGTATAGAGCCCTA\nACCATATATAGAGAGACAC\n";
$newfa[1] = $faseq;
push @newfa, ">testfa2\nAGAGAGAGAGTAAAAcgatcgagtc";
ok (@newfa == 302, "OK Pushing");
pop (@newfa);
ok (@newfa == 301, "OK Poping");
@newfa="";
splice (@newfa,0,1,@arr);
ok (@newfa == 301, "OK Splicing");

untie @arr;
untie @newfa;
unlink "t/Data/exnew.fa";


#####################################################################

my $exbad = "t/Data/ex_bad.fa";
tie my @arrX, 'Tie::File::AnyData::Bio::Fasta',$exbad;
ok (@arrX == 3, 'OK number of fasta seqs II');
tie my @arrXnew, 'Tie::File::AnyData::Bio::Fasta', "t/Data/kk.fa";
@arrXnew = reverse @arrX;
ok (@arrXnew == 3, 'OK number of fasta seqs III');
untie @arrX;
untie @arrXnew;

unlink @arrXnew;
