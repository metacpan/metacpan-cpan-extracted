#!/usr/bin/perl -w

use strict;
use Benchmark;
use IO::File;
use Tie::GHash;

my $fh = IO::File->new('/usr/share/dict/words');
my @words = <$fh>;
chomp @words;

my %words;
tie my %words_ghash, 'Tie::GHash';
my $i = 0;
foreach (@words) {
  $words{$_} = $i++;
  $words_ghash{$_} = $i++;
}

timethese(-10, {
		   'insert' => \&insert,
		   'insert_ghash' => \&insert_ghash,
		   'fetch' => \&fetch,
		   'fetch_ghash' => \&fetch_ghash,
		   'delete' => \&delete,
		   'delete_ghash' => \&delete_ghash,
		  });

sub insert {
  my %h;
  my $i;
  foreach (@words) {
    $h{$_} = $i++;
  }
}

sub insert_ghash {
  tie my %h, 'Tie::GHash';
  my $i;
  foreach (@words) {
    $h{$_} = $i++;
  }
}

sub fetch {
  my $v;
  foreach (@words) {
    $v = $words{$_};
  }
}

sub fetch_ghash {
  my $v;
  foreach (@words) {
    $v = $words_ghash{$_};
  }
}

sub delete {
  my %h;
  my $i;
  foreach (@words) {
    $h{$_} = $i++;
    delete $h{$_};
  }
}

sub delete_ghash {
  tie my %h, 'Tie::GHash';
  my $i;
  foreach (@words) {
    $h{$_} = $i++;
    delete $h{$_};
  }
}
