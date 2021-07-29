use strict;
use warnings;
use 5.024;

package Vote::Count::Helper::Table;
no warnings 'experimental';
use feature qw /postderef signatures/;
use Sort::Hash;
use Vote::Count::TextTableTiny qw/generate_table/;

our $VERSION='2.01';

# ABSTRACT: Non OO Components for the Vote::Charge implementation of STV.

=head1 NAME

Vote::Count::Helper::Table

=head1 VERSION 2.01

=head1 Description

Table Formatting Helpers for use within Vote::Count.

=cut

=pod

=head1 SYNOPSIS

  use Vote::Count::Helper::Table 'ChargeTable';
  # $chargesPerChoice and $chargedPerChoice are from Vote::Count::Charge::Cascade
  say ChargeTable( $chargesPerChoice, $chargedPerChoice );

  use Vote::Count::Helper::Table 'WeightedTable';
  # When weighted voting is used will generate a table
  # with the Top Count and Approval totals
  say WeightedTable( $STV_Election );

=cut

use Exporter::Easy (
  OK => [ 'WeightedTable', 'ChargeTable' ],
);

=head2 ChargeTable

Arguments: $chargesPerChoice, $chargedPerChoice

chargesPerChoice is a HashRef with the choices as keys, and the values the charge assessed each ballot supporting the choice.

chargedPerChoice is a HashRef with the choices as keys and the values a HashRef with the keys value, count, surplus, where value is the total vote value charged for the choice, count is the number of ballots that contributed, and surplus the value above quota charged.

=cut

sub ChargeTable ( $chargesPerChoice, $chargedPerChoice ) {
  my @rows = (['Choice','Charge','Value Charged', 'Votes Charged','Surplus'] );
  for my $c ( sort keys $chargesPerChoice->%* ) {
    push @rows, [
      $c, $chargesPerChoice->{$c},
      $chargedPerChoice->{$c}{'value'},
      $chargedPerChoice->{$c}{'count'},
      $chargedPerChoice->{$c}{'surplus'}
    ]
  }
  return generate_table(
      rows => \@rows,
      style => 'markdown',
      align => [qw/ l l r r r/]
      ) . "\n";
}

=head2 WeightedTable

Formats the current Vote Totals by Approval and Top Count when weighted voting is in use, for STV/Vote Charge methods.

=cut

sub WeightedTable ( $I ) {
  my $approval = $I->Approval()->RawCount();
  my $tc = $I->TopCount();
  my $tcr = $tc->RawCount();
  my $vv = $I->VoteValue();
  my %data =();
  my @active = $I->GetActiveList();
  for my $choice ( @active ) {
    $data{ $choice } = {
      'votevalue' => $tcr->{ $choice },
      'votes' => sprintf( "%.2f",$tcr->{ $choice } / $vv),
      'approvalvalue' => $approval->{ $choice },
      'approval' => sprintf( "%.2f", $approval->{ $choice } / $vv),
    };
  }
  my @rows = ( [ 'Rank', 'Choice', 'Votes', 'VoteValue', 'Approval', 'Approval Value' ] );
  my %byrank = $tc->HashByRank()->%*;
  for my $r ( sort { $a <=> $b } ( keys %byrank ) ) {
    my @choice = sort $byrank{$r}->@*;
    for my $choice (@choice) {
      # my $votes = $tcr->{$choice};
      my $D = $data{$choice};
      my @row = (
          $r, $choice, $D->{'votes'}, $D->{'votevalue'},
          $D->{'approval'}, $D->{'approvalvalue'} );
      push @rows, ( \@row );
    }
  }
  return generate_table(
    rows => \@rows,
    style => 'markdown',
    align => [qw/ l l r r r r/]
    ) . "\n";
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

