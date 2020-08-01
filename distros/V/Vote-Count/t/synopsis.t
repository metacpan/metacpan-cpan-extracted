#!/usr/bin/env perl

=pod

This test is just here for testing code samples given in the synopsis section or elsewhere.

=cut

use 5.022;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;

# use Path::Tiny;
use Vote::Count;
use Vote::Count::ReadBallots;
use Vote::Count::Method::CondorcetDropping;

# cut and paste the synopsis section from count.md here
# whenever it changes to validate the synopsis. clip out any
# boiler plate already provided above.

  # example uses biggerset1 from the distribution test data.
  my $ballotset = read_ballots 't/data/biggerset1.txt' ;
  my $CondorcetElection =
    Vote::Count::Method::CondorcetDropping->new(
      'BallotSet' => $ballotset ,
      'DropStyle' => 'all',
      'DropRule'  => 'topcount',
    );
  # ChoicesAfterFloor a hashref of choices meeting the
  # ApprovalFloor which defaulted to 5%.
  my $ChoicesAfterFloor = $CondorcetElection->ApprovalFloor();
  # Apply the ChoicesAfterFloor to the Election.
  $CondorcetElection->SetActive( $ChoicesAfterFloor );
  # Get Smith Set and the Election with it as the Active List.
  my $SmithSet = $CondorcetElection->Matrix()->SmithSet() ;
  $CondorcetElection->logt(
    "Dominant Set Is: " . join( ', ', keys( $SmithSet->%* )));
  my $Winner = $CondorcetElection->RunCondorcetDropping( $SmithSet )->{'winner'};

  # Create an object for IRV, use the same Floor as Condorcet

  my $IRVElection = Vote::Count->new(
    'BallotSet' => $ballotset,
    'Active' => $ChoicesAfterFloor );
  # Get a RankCount Object for the
  my $Plurality = $IRVElection->TopCount();
  my $PluralityWinner = $Plurality->Leader();
  $IRVElection->logv( "Plurality Results", $Plurality->RankTable);
  if ( $PluralityWinner->{'winner'}) {
    $IRVElection->logt( "Plurality Winner: ", $PluralityWinner->{'winner'} )
  } else {
    $IRVElection->logt(
      "Plurality Tie: " . join( ', ', $PluralityWinner->{'tied'}->@*) )
  }
  my $IRVResult = $IRVElection->RunIRV();

  # Now print the logs and winning information.
  say $CondorcetElection->logv();
  say $IRVElection->logv();
  say '*'x60;
  say "Plurality Winner: $PluralityWinner->{'winner'}";
  say "IRV Winner: $IRVResult->{'winner'}";
  say "Condorcet Winner: $Winner";


# End cut and paste from synpsis

is( $PluralityWinner->{'winner'}, 'VANILLA',  'Check Plurality Winner' );
is( $IRVResult->{'winner'},       'MINTCHIP', 'Check the IRV Result' );
is( $Winner,                      'MINTCHIP', 'The Condorcet Result' );

done_testing();
