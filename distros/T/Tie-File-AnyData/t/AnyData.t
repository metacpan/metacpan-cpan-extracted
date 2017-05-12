#!/usr/bin/perl

use strict;
use warnings;

#use List::Util;
use Test::More tests => 12;

BEGIN {
  use_ok ('Tie::File::AnyData');   ## Test 1
}

#can_ok ('IO::Tie::File::AnyData',qw/TIEARRAY PUSH STORE _read_record/);
can_ok ('Tie::File', qw/_read_record/);  ## Test 2
my $file2seq = "t/data/seq2.fa";

## Test
eval {
  tie my @farr, 'Tie::File::AnyData',$file2seq,unknown_opt => 1;
};
ok ($@ =~ /AnyData/s, "Carp OK");

tie my @farr2s, 'Tie::File::AnyData', $file2seq;
ok (@farr2s == 4, "FETCHARRAY works OK");  ## Test 3

is ($farr2s[0], ">seq1","1st record ok");  ## Test 4
is ($farr2s[2], ">seq2","2nd record ok");  ## Test 5

my $coderef = sub {
  my ($fh) = @_;
  #  my $fh = $self->{fh};
  return undef if eof $fh;
  local $/ = "\n>";
  my $faseq = <$fh>;
  if (eof $fh) {
    local $/ = "\n";
    chomp $faseq;
  } else {
    chomp $faseq;
  }
  $faseq = ">$faseq" if $faseq !~ /^>/;
  return "$faseq\n";
};

tie my @farrX, 'Tie::File::AnyData', $file2seq, code => $coderef;

ok (@farrX == 2, "FETCHARRAY fasta works OK (I)"); ## Test 6

my $file301seq = "t/data/ex2.fa";
tie my @farrM, 'Tie::File::AnyData', $file301seq, code => $coderef;
ok (@farrM == 301, "FETCHARRAY fasta works OK (II)"); ## Test 7

like ($farrM[0], qr/^>Bg11e/s,'Record OK');
like ($farrM[0], qr/gctcccaatta$/s, 'Record OK (II)');

###################

my $gfffile = "t/data/apsid.Sorted.gff";
my $coderefgff = sub {
  my ($fh) = @_;
  my $rec = '';
  return undef if (eof $fh);
  my $line = <$fh>;
  $rec .= $line;
  my $rec_key = (split /\t/, $line)[0];
  my $pos = tell ($fh);
  while ($line = <$fh>){
    if ((split /\t/,$line)[0] eq $rec_key){
      $rec.=$line;
      $pos = tell ($fh);
      return $rec if eof ($fh);
    } else {
      seek $fh, $pos, 0;
      return $rec;
    }
  }
};
tie my @gff205, 'Tie::File::AnyData', $gfffile, code => $coderefgff;
ok (@gff205 == 205, "FETCHARRAY on gff OK");
ok (@farrM == 301, "FETCHARRAY fasta works OK (III)"); ## Test 

untie @gff205;
untie @farrX;
untie @farrM;
