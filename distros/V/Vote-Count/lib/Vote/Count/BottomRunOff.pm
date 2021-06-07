package Vote::Count::BottomRunOff;
use Moose::Role;

use 5.024;
no warnings 'experimental';
use feature ( 'signatures');

our $VERSION='2.00';

=head1 NAME

Vote::Count::BottomRunOff

=head1 VERSION 2.00

=head2 Description

Bottom RunOff is an elimination method which takes the two lowest choices, usually by Top Count, but alternately by another method such as Approval or Borda, the choice which would lose a runoff is eliminated.

=head1 Synopsis

  my $eliminate = $Election->BottomRunOff();
  # log the pairing result
  $Election->logd( $eliminate->{'runoff'} );
  $Election->logv( "eliminated ${\ $eliminate->{'eliminate'} }."
  $Election->Defeat( $eliminate->{'eliminate'} );

=head1 BottomRunOff ($method)

The TieBreakMethod must either be 'precedence' or TieBreakerFallBackPrecedence must be true or BottomRunOff will die. It takes a parameter of method, which is the method used to rank the active choices. The default method is 'TopCount', 'Approval' is a common alternative, any method which returns a RankCount object could be used.

  my $result = BottomRunOff( $Election, 'Approval' );

The returned value is a hashref with the keys: B<eliminate>, B<continuing>, and B<runoff>, runoff is formatted as a table.

=cut

sub BottomRunOff ( $Election, $method1='TopCount' ) {
  my @ranked = $Election->UntieActive($method1, 'precedence' )->OrderedList();
  my ( $continuing, $eliminate ) = $Election->UnTieList( 'TopCount', $ranked[-1],  $ranked[-2]);
  my $tc = $Election->$method1( { $continuing => 1,  $eliminate => 1} );
  return {
    eliminate => $eliminate,
    continuing => $continuing,
    runoff => "Elimination Runoff:\n${\ $tc->RankTable }"
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

