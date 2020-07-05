#!/usr/bin/env perl

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
# use Data::Printer;
use Data::Dumper;
# use JSON::MaybeXS;
# use YAML::XS;
use feature qw /postderef signatures/;

# my $json = JSON::MaybeXS->new( utf8 => 1, pretty => 1 );

use Path::Tiny;

use Vote::Count::Method::CondorcetDropping;
use Vote::Count::ReadBallots 'read_ballots';

# Lack of testing getround was exposed from devel cover
# required a lot of comparison hashes 

subtest 'GetRound' => sub {


  my $M = Vote::Count::Method::CondorcetDropping->new(
    'BallotSet'     => read_ballots('t/data/ties1.txt'),
    'DropStyle'     => 'all',
    'DropRule'      => 'topcount',
    'SkipLoserDrop' => 1,
  );


  my $rtc =  {
'MINTCHIP' => 4,
'PISTACHIO' => 4,
'ROCKYROAD' => 4,
'CHOCCHUNK' => 2,
'FUDGESWIRL' => 6,
'STRAWBERRY' => 0,
'VANILLA' => 6,
'CHERRY' => 0,
'CARAMEL' => 0,
'CHOCOLATE' => 0,
'BUBBLEGUM' => 2,
'RUMRAISIN' => 4
                 };

  my $rappr =  {
'MINTCHIP' => 8,
'PISTACHIO' => 4,
'ROCKYROAD' => 5,
'CHOCCHUNK' => 2,
'FUDGESWIRL' => 6,
'STRAWBERRY' => 4,
'VANILLA' => 6,
'CHERRY' => 6,
'CARAMEL' => 4,
'CHOCOLATE' => 6,
'BUBBLEGUM' => 6,
'RUMRAISIN' => 4
                 };                 

  my $rborda =  {
'MINTCHIP' => 88,
'PISTACHIO' => 48,
'ROCKYROAD' => 59,
'CHOCCHUNK' => 24,
'FUDGESWIRL' => 72,
'STRAWBERRY' => 40,
'VANILLA' => 72,
'CHERRY' => 66,
'CARAMEL' => 44,
'CHOCOLATE' => 62,
'BUBBLEGUM' => 68,
'RUMRAISIN' => 48
                 };

my $rgl = {
'PISTACHIO' => 4,
'VANILLA' => 0,
'RUMRAISIN' => 4,
'STRAWBERRY' => 6,
'CHOCCHUNK' => 4,
'CARAMEL' => 8,
'ROCKYROAD' => 3,
'MINTCHIP' => 2,
'FUDGESWIRL' => 2
};

note $M->DropRule();
  my $active = $M->GetActive();
  is_deeply( $M->GetRound( $active, 1 )->RawCount(),
    $rtc, 
    'GetRound method with topcount droprule');
  $M->{'DropRule'}   = 'approval';
  is_deeply( $M->GetRound( $active, 1 )->RawCount(),
    $rappr, 
    'GetRound method with approval droprule');

  $M->{'DropRule'}   = 'borda';
  is_deeply( $M->GetRound( $active, 1 )->RawCount(),
    $rborda, 
    'GetRound method with borda droprule');

  $M->{'DropRule'}   = 'greatestloss';

  # for this test the result has is fed as an active list
  # to check with a non-default active set.
  is_deeply( $M->GetRound( $rgl, 1 )->RawCount(),
    $rgl, 
    'GetRound method with greatestloss droprule');  

  $M->{'DropRule'}   = 'invented';  
dies_ok(
    sub { $M->GetRound( $active, 1 ) ; },
    "unkown droprule dies on call of GetRound"
  );
};

done_testing();
