use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures/;

# ABSTRACT: Toolkit for implementing voting methods.

package Vote::Count;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

use Data::Dumper;
use Time::Piece;
use Path::Tiny;
use Vote::Count::Matrix;
# use Storable 3.15 'dclone';

no warnings 'experimental';

our $VERSION='2.04';

=head1 NAME

Vote::Count - a tool kit for preferential ballots

=head1 VERSION 2.04

=head2 A Toolkit for Resolving Preferential Ballots.

Vote::Count provides a combination of methods and variations for conducting elections and studying different methods of resolving preferential ballots.

=head1 DOCUMENTATION

=head2 L<OVERVIEW|Vote::Count::Overview>

An overview of Preferential Voting and an introduction to Vote::Count. Read this document first.

=head2 L<COMMON|Vote::Count::Common>

The core methods of Vote::Count are documented in this Module.

=head2 L<CATALOG|Vote::Count::Catalog>

Catalog of Preferential Voting Methods implemented by Vote::Count and the Modules providing them.

=head2 L<MULTIMEMBER|Vote::Count::MultiMember>

Overview of Preferential Ballots for Multi-Member Elections and their implementation in Vote::Count.

=cut

# This should be in tiebreaker's BUILD but
# I've found role's BUILD unreliable.
sub _tiebreakvalidation ( $self ) {
  if ( defined $self->TieBreakMethod ) {
    if ( lc( $self->TieBreakMethod ) eq 'precedence' ) {
      unless ( defined $self->PrecedenceFile() ) {
        die
'Precedence File must be defined when setting TieBreakMethod to Precedence';
      }
    }
  }
  if ( $self->TieBreakerFallBackPrecedence ) {
    no warnings 'uninitialized';
    my $tb = $self->TieBreakMethod;
    if ( $tb eq 'none' or $tb eq 'all' or !defined($tb) ) {
      die
"FATAL: TieBreakerFallBackPrecedence will not be triggered if the TieBreakMethod is none, all or undefined.\n";
    }
  }
}

sub BUILD {
  my $self = shift;
  # Verbose Log
  $self->{'LogV'} = localtime->cdate . "\n";
  # Debugging Log
  $self->{'LogD'} = qq/Vote::Count Version $VERSION\n/;
  $self->{'LogD'} .= localtime->cdate . "\n";
  # Terse Log
  $self->{'LogT'} = '';
# Force build of Active, Methods that deal with it often go to $self->{'Active'}
# make sure it is built before this happens, Active has to be built after
# loading ballotset.
  $self->GetActive();
  $self->_tiebreakvalidation();
}

# load the roles providing the underlying ops.
with
  'Vote::Count::Common',
  'Vote::Count::Approval',
  'Vote::Count::Borda',
  'Vote::Count::BottomRunOff',
  'Vote::Count::Floor',
  'Vote::Count::IRV',
  'Vote::Count::Log',
  'Vote::Count::Score',
  'Vote::Count::TieBreaker',
  'Vote::Count::TopCount',
  ;

__PACKAGE__->meta->make_immutable;
1;

#INDEXSECTION

=pod

=head1 INDEX of Vote::Count Modules and Documentation

=over

=item *

L<Vote::Count - a tool kit for preferential ballots>

=item *

L<Vote::Count::Approval>

=item *

L<Vote::Count::Borda>

=item *

L<Vote::Count::BottomRunOff>

=item *

L<Vote::Count::Catalog>

=item *

L<Vote::Count::Charge>

=item *

L<Vote::Count::Charge::Cascade>

=item *

L<Vote::Count::Common>

=item *

L<Vote::Count::Floor>

=item *

L<Vote::Count::Helper>

=item *

L<Vote::Count::Helper::FullCascadeCharge>

=item *

L<Vote::Count::Helper::NthApproval>

=item *

L<Vote::Count::Helper::Table>

=item *

L<Vote::Count::Helper::TestBalance;>

=item *

L<Vote::Count::IRV>

=item *

L<Vote::Count::Log>

=item *

L<Vote::Count::Matrix>

=item *

L<Vote::Count::Method::Cascade>

=item *

L<Vote::Count::Method::CondorcetDropping>

=item *

L<Vote::Count::Method::CondorcetIRV>

=item *

L<Vote::Count::Method::CondorcetVsIRV>

=item *

L<Vote::Count::Method::MinMax>

=item *

L<Vote::Count::Method::STAR>

=item *

L<Vote::Count::Method::WIGM>

=item *

L<Vote::Count::MultiMember - Overview of Multi Member and Proportional Elections and Vote::Count support for them.>

=item *

L<Vote::Count::Overview>

=item *

L<Vote::Count::Range>

=item *

L<Vote::Count::RankCount>

=item *

L<Vote::Count::ReadBallots>

=item *

L<Vote::Count::Redact>

=item *

L<Vote::Count::Score>

=item *

L<Vote::Count::Start>

=item *

L<Vote::Count::TextTableTiny>

=item *

L<Vote::Count::TieBreaker>

=item *

L<Vote::Count::TopCount>

=back

=cut

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

