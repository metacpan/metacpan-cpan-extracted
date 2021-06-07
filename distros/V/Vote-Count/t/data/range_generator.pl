#!/usr/bin/env perl

=pod

generate range ballots from data structures for testing.

=cut

use 5.024;

use JSON::MaybeXS;
use YAML::XS;
use Data::Printer;
use Path::Tiny;
use Try::Tiny;
use Storable 3.15 qw(dclone);

my $coder = Cpanel::JSON::XS->new->ascii->pretty;

# This is the tennessee example inferred to Range Ballot
#
my $tennessee = {
  choices => [ "CHATTANOOGA", "KNOXVILLE", "MEMPHIS", "NASHVILLE" ],
  depth   => 5,
  ballots => [
    {
      "count" => 15,
      "votes" => {
        "CHATTANOOGA" => 5,
        "KNOXVILLE"   => 4,
        "NASHVILLE"   => 3,
        "MEMPHIS"     => 1
      }
    },
    {
      "count" => 17,
      "votes" => {
        "CHATTANOOGA" => 4,
        "KNOXVILLE"   => 5,
        "NASHVILLE"   => 3,
        "MEMPHIS"     => 1
      }
    },
    {
      "count" => 26,
      "votes" => {
        "CHATTANOOGA" => 4,
        "KNOXVILLE"   => 3,
        "NASHVILLE"   => 5,
        "MEMPHIS"     => 1
      }
    },
    {
      "count" => 42,
      "votes" => {
        "CHATTANOOGA" => 1,
        "KNOXVILLE"   => 2,
        "NASHVILLE"   => 3,
        "MEMPHIS"     => 5
      }
    },
  ],
};

# this is just made up junk to generate a range ballot where a lot
# of choices are equal.

my $fastfood = {
  choices => [
    qw( FIVEGUYS MCDONALDS WIMPY WENDYS QUICK BURGERKING INNOUT CARLS KFC TACOBELL CHICKFILA POPEYES )
  ],
  depth   => 3,
  ballots => [
    {
      "count" => 3,
      "votes" => [
        [qw /MCDONALDS QUICK WENDYS/], [qw /QUICK BURGERKING/],
        [qw /KFC TACOBELL CHICKFILA POPEYES/],
      ]
    },
    {
      "count" => 1,
      "votes" => [ [qw /TACOBELL/], [qw /KFC/], [qw /CHICKFILA POPEYES/], ]
    },
    {
      "count" => 2,
      "votes" => [ [qw /CHICKFILA/], [qw /INNOUT/], [qw //], ]
    },
    {
      "count" => 2,
      "votes" => [ [qw /INNOUT/], [qw //], [qw /MCDONALDS BURGERKING/], ]
    },
    {
      "count" => 1,
      "votes" => [ [qw //], [qw /CARLS/], [qw //], ]
    },
    {
      "count" => 6,
      "votes" => [ [qw /INNOUT/], [qw /FIVEGUYS/], [qw /CARLS BURGERKING/], ]
    },
  ],
};

for my $B ( $fastfood->{'ballots'}->@* ) {
  my %new = ();
  for ( my $i = 0; $i < $fastfood->{'depth'}; $i++) {
      my $score = 3 - $i;
      for my $V ( $B->{'votes'}[$i]->@*) {
        next unless $V gt ' ';
        $new{$V} = $score;
      }
  }
  $B->{'votes'} = \%new;
}

# p $fastfood;
# p $tennessee;
path('t/data/tennessee.range.json')->spew( $coder->encode($tennessee) );
path('t/data/tennessee.range.yml')->spew( Dump $tennessee);
path('t/data/fastfood.range.json')->spew( $coder->encode($fastfood) );
path('t/data/fastfood.range.yml')->spew( Dump $fastfood);
