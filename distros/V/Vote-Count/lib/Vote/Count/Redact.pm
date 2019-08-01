package Vote::Count::Redact;

use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;
use Storable 3.15 qw(dclone);

use namespace::autoclean;

use Data::Printer;

no warnings 'experimental';

our $VERSION='0.013';

=head1 NAME

Vote::Count::Redact

=head1 VERSION 0.013

=cut

# ABSTRACT: Methods for Redacting Vote::Count BallotSets.

use Exporter::Easy (
       OK => [ qw( RedactSingle RedactPair ) ],
   );

# Redact only one choice
# level = depth of choices to redact, 1 truncates the ballot if $A is choice 1
# level of 0 sets no limit if $A is choice 7, all remaining choices truncate.
sub RedactSingle( $self, $A, $level=1 ) {
...
}

=head2 method RedactPair

For a Ballot Set and two choices, on each ballot where both appear it removes the later one, returning a completely independent new BallotSet.

  my $newBallotSet = RedactPair( $VoteCountObject->BallotSet(), 'A', 'B');

=cut

sub RedactPair ( $ballotset, $A, $B ) {
  my $new     = dclone($ballotset);
  my %ballots = $new->{'ballots'}->%*;
REDACTPAIRLOOP:
  for my $ballot ( keys %ballots ) {
    my @newvote = ();
    my @oldvote = $ballots{$ballot}{'votes'}->@*;
    while (@oldvote) {
      my $v = shift @oldvote;
      push @newvote, $v;
      if ( $v eq $A ) {
        while (@oldvote) {
          my $u = shift @oldvote;
          push @newvote, ($u) unless $u eq $B;
        }
      }
      elsif ( $v eq $B ) {
        while (@oldvote) {
          my $u = shift @oldvote;
          push @newvote, ($u) unless $u eq $A;
        }
      }
      else { }
      $ballots{$ballot}{'votes'} = \@newvote;
    }
  }
  $new->{'ballots'} = \%ballots;
  return $new;
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

