use strict;
use warnings;
use 5.024;
# use feature qw /postderef signatures/;

package Vote::Count::Helper::TestBalance;

our $VERSION='2.01';

# ABSTRACT: Custom Test for checking STV charge calculations.

=head1 NAME

Vote::Count::Helper::TestBalance;

=head1 VERSION 2.01

=head1 Synopsis

  my $Charges = { 'choice1' => 55, 'choice2' => 79 };
  my $balanceValue = $remaining_vote_value;
  balance_ok( $BallotSet, $charges, $balanceValue, [ @elected ], $test_name);

=head1 balance_ok

Compare current charges with the ballotset and the remaining vote_value to confirm that the charges would balance. Used for testing FullCascade Charge.

This method is exported.

=cut

use Test2::API qw/context/;

our @EXPORT = qw/balance_ok/;
use base 'Exporter';

sub balance_ok :prototype($$$$;$) {
  my ( $Ballots, $charge, $balance, $elected, $name ) = @_;
  $name = 'check balance of charges and votes' unless $name;
  my $valelect = 0;
  for ( @{$elected} ) {
    $valelect += $charge->{$_}{'value'};
  }
  my $valremain = 0;
  for my $k ( keys $Ballots->%* ) {
    $valremain +=
      $Ballots->{$k}{'votevalue'} * $Ballots->{$k}{'count'};
  }
  my $valsum = $valremain + $valelect;
  my $warning = "### $valsum ($valremain + $valelect) != $balance ###";
  my $ctx = context();    # Get a context
    $ctx->ok( $valsum == $balance, $name, [ "$name\n\t$warning"] );
  $ctx->release;    # Release the context
  return 1;
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

