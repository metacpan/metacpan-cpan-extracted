package Vote::Count::BottomRunOff;
use Moose::Role;

use 5.024;
no warnings 'experimental';
use feature ('signatures');
use Carp;
use Data::Dumper;
use Data::Printer;

our $VERSION = '2.01';

=head1 NAME

Vote::Count::BottomRunOff

=head1 VERSION 2.01

=head2 Description

Bottom RunOff is an elimination method which takes the two lowest choices, the choice which would lose a runoff is eliminated.

=head1 Synopsis

  my $eliminate = $Election->BottomRunOff();
  # log the pairing result
  $Election->logd( $eliminate->{'runoff'} );
  # log elimination in the short log too.
  $Election->logt( "eliminated ${\ $eliminate->{'eliminate'} }.");
  # Perform the elimination
  $Election->Defeat( $eliminate->{'eliminate'} );

=head1 BottomRunOff

The TieBreakMethod must either be 'precedence' or TieBreakerFallBackPrecedence must be true or BottomRunOff will die. Takes an optional named parameter of an active set.

  my $result = $Election->BottomRunOff();
  my $result = $Election->BottomRunOff( 'active' => $active );
  my $result = $Election->BottomRunOff( 'ranking2' => $othermethod );

Orders the Choices according to Top Count and uses Precedence to resolve any equal rankings. Then conducts a runoff between the two lowest choices in the order.

The returned value is a hashref with the keys: B<eliminate>, B<continuing>, and B<runoff>, runoff describes the totals for the two choices in the runoff.

The optional values are B<ranking2> and B<active>. See UnTieList in L<Vote::Count::TieBreaker|Vote::Count::TieBreaker/UnTieList>, the B<ranking1> passed to it is always B<TopCount>.  B<active> is used to provide a hashref to override the current active list.

=cut

sub BottomRunOff ( $Election, %args ) {
  # IRV segregates its active set so BottomRunOff needs to accept one
  my $active = defined $args{'active'}
          ? $args{'active'}
          : $Election->GetActive ;

  my $ranking2 = $args{'ranking2'} ? $args{'ranking2'} : 'Precedence';
  my @ranked = $Election->UnTieList(
    'ranking1' => 'TopCount',
    'ranking2' => $ranking2,
    'tied'     => [ keys $active->%* ],
  );

  my $pairing =
    $Election->PairMatrix()->GetPairResult( $ranked[-2], $ranked[-1] );
  my $continuing = $pairing->{'winner'};
  my $eliminate  = $pairing->{'loser'};
  # pairing should never be a tie because precedence must be enabled,
  # there should be no ties in the Matrix.
  my $runoffmsg =
qq/Elimination Runoff: *$continuing* $pairing->{$continuing} > $eliminate $pairing->{$eliminate}/;
  return {
    eliminate  => $eliminate,
    continuing => $continuing,
    runoff     => $runoffmsg
  };
}

1;

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

