#!/usr/bin/perl

use strict;
use Benchmark;
use Tree::Ternary;
use Tree::Ternary_XS;
use IO::File;
use constant WORDS => '/usr/dict/words';


my $times = -20;

my @words = get_words();


my(%h, $t, $xs);

print "** insert **\n";
timethese($times,
	  {
	   'Ternary' => sub { $t = bench_perl_insert() },
	   'Hash' => sub { %h = bench_hash_insert() },
	   'Ternary_XS' => sub { $xs = bench_xs_insert() },
	  });

print "\n** search **\n";
timethese($times,
	  {
	   'Ternary' => sub { bench_perl_search($t) },
	   'Hash' => sub { bench_hash_search(%h) },
	   'Ternary_XS' => sub { bench_xs_search($xs) },
	  });

print "\n** pmsearch **\n";
timethese($times,
	  {
	   'Ternary' => sub { bench_perl_pmsearch($t) },
	   'Ternary_XS' => sub { bench_xs_pmsearch($xs) },
	  });

print "\n** nearsearch **\n";
timethese($times,
	  {
	   'Ternary' => sub { bench_perl_nearsearch($t) },
	   'Ternary_XS' => sub { bench_xs_nearsearch($xs) },
	  });


sub get_words {
  my @words;

  my $fh = IO::File->new(WORDS);
  @words = <$fh>;
  $fh->close;

  chomp @words;

  return @words;
}



# INSERT

sub bench_xs_insert {
  my $tree = Tree::Ternary_XS->new();

  foreach my $word (@words) {
    $tree->insert($word);
  }

  return $tree;
}

sub bench_perl_insert {
  my $tree = Tree::Ternary->new();

  foreach my $word (@words) {
    $tree->insert($word);
  }

  return $tree;
}


sub bench_hash_insert {
  my %h;

  foreach my $word (@words) {
    $h{$word} = 1;
  }

  return %h;
}



# SEARCH

sub bench_xs_search {
  my $tree = shift;

  foreach my $word (@words) {
    die unless $tree->search($word);
  }
}

sub bench_perl_search {
  my $tree = shift;

  foreach my $word (@words) {
    die unless $tree->search($word);
  }
}

sub bench_hash_search {
  my %h = @_;

  foreach my $word (@words) {
    die "$word not found!\n" unless exists $h{$word};
  }
}





# PMSEARCH

sub bench_xs_pmsearch {
  my $tree = shift;

  foreach my $word (@words) {
    die unless $tree->pmsearch("e", $word);
  }
}

sub bench_perl_pmsearch {
  my $tree = shift;

  foreach my $word (@words) {
    die unless $tree->pmsearch("e", $word);
  }
}





# NEARSEARCH

sub bench_xs_nearsearch {
  my $tree = shift;

  my $count = 0;
  foreach my $word (@words) {
    last if $count++ == 100;
    die unless $tree->nearsearch(1, $word);
  }
}

sub bench_perl_nearsearch {
  my $tree = shift;

  my $count = 0;
  foreach my $word (@words) {
    last if $count++ == 100;
    die unless $tree->nearsearch(1, $word);
  }
}






