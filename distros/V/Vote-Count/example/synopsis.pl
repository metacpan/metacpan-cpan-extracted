#!/usr/bin/env perl

=pod

Script to test the synopsis code sample!

=cut

# Synopsis

  use 5.022; # Minimum Perl, or any later Perl.
  use feature qw /postderef signatures/;

  use Vote::Count;
  use Vote::Count::ReadBallots;
  use Vote::Count::Method::CondorcetDropping;

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
  $CondorcetElection->Active( $ChoicesAfterFloor );
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
  # In case of ties RankCount objects return top as an array, log the result.
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

