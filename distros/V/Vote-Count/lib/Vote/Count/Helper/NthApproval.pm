use strict;
use warnings;
use 5.024;

package Vote::Count::Helper::NthApproval;
use Moose::Role;
no warnings 'experimental';
use feature qw /postderef signatures/;
# use Vote::Count::TextTableTiny qw/generate_table/;

our $VERSION='2.04';

# ABSTRACT: Nth Approval Defeat rule for STV elections.

=head1 NAME

Vote::Count::Helper::NthApproval

=head1 VERSION 2.04

=cut

=pod

=head1 SYNOPSIS

  package MySTVElection;
  use Moose;
  extends 'Vote::Count::Charge';
  with 'Vote::Count::Charge::NthApproval';
  for my $defeat ( NthApproval( $STV_Election ) ) {
     $STV_Election->Defeat( $defeat );
  }

=head1 NthApproval

Finds the choice that would fill the last seat if the remaining seats were to be filled by highest Top Count, and sets the Vote Value for that Choice as the requirement. All Choices that do not have a weighted Approval greater than that requirement are returned, they will never be elected and are safe to defeat immediately.

Results are logged to the verbose log.

This rule is not strictly LNH safe.

=cut

sub NthApproval ( $I ) {
  my $tc            = $I->TopCount();
  my $ac            = $I->Approval();
  my $seats         = $I->Seats() - $I->Elected();
  my @defeat        = ();
  my $bottomrunning = $tc->HashByRank()->{$seats}[0];
  my $bar           = $tc->RawCount()->{$bottomrunning};
  for my $A ( $I->GetActiveList ) {
    next if $A eq $bottomrunning;
    my $avv = $ac->{'rawcount'}{$A};
    push @defeat, ($A) if $avv <= $bar;
  }
  if (@defeat) {
    $I->logv( qq/
      Seats: $seats Choice $seats: $bottomrunning ( $bar )
      Choices Not Over $bar by Weighted Approval: ${\ join( ', ', @defeat ) }
    /);
  }
  return @defeat;
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

