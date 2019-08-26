use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::Approval;
use Moose::Role;

no warnings 'experimental';
# use Data::Printer;

our $VERSION='0.022';

=head1 NAME

Vote::Count::Approval

=head1 VERSION 0.022

=cut

# ABSTRACT: RankCount object for Vote::Count. Toolkit for vote counting.

=head1 Definition of Approval

In Approval Voting, voters indicate which Choices they approve of indicating no preference. Approval can be infered from a Ranked Choice Ballot, by treating each ranked Choice as Approved.

=head1 Method Approval

Returns a RankCount object for the current Active Set taking an optional argument of an active list as a HashRef.

  my $Approval = $Election->Approval();
  say $Approval->RankTable;

=cut

sub Approval ( $self, $active=undef ) {
  my %BallotSet = $self->BallotSet()->%*;
  my %ballots = ( $BallotSet{'ballots'}->%* );
  $active = $self->Active() unless defined $active ;
  my %approval = ( map { $_ => 0 } keys( $active->%* ));
    for my $b ( keys %ballots ) {
      my @votes = $ballots{$b}->{'votes'}->@* ;
      for my $v ( @votes ) {
        if ( defined $approval{$v} ) {
          $approval{$v} += $ballots{$b}{'count'};
        }
      }
    }
  return Vote::Count::RankCount->Rank( \%approval );
}

1;

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut

