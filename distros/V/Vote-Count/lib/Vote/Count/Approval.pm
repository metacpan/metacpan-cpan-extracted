use strict;
use warnings;
use 5.022;

use feature qw /postderef signatures/;

package Vote::Count::Approval;
$Vote::Count::Approval::VERSION = '0.013';
use Moose::Role;

no warnings 'experimental';
# use Data::Printer;

sub Approval ( $self, $active=undef ) {
  my %BallotSet = $self->BallotSet()->%*;
  my %ballots = ( $BallotSet{'ballots'}->%* );
# p %ballots;
  $active = $BallotSet{'choices'} unless defined $active ;
# p $active;
  my %approval = ( map { $_ => 0 } keys( $active->%* ));
    for my $b ( keys %ballots ) {
# warn "checkijng $b";
# p $ballots{$b};
# return {};
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

