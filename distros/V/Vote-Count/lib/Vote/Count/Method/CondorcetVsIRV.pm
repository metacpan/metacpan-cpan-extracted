use strict;
use warnings;
use 5.022;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetVsIRV;
use namespace::autoclean;
use Moose;

with 'Vote::Count::Log';

# use Exporter::Easy ( EXPORT => [ 'CondorcetVsIRV' ] );

# use Vote::Count;
# use Vote::Count::Method::CondorcetIRV;
use Storable 3.15 'dclone';
use Vote::Count::ReadBallots qw/read_ballots write_ballots/;
use Vote::Count::Redact qw/RedactSingle RedactPair RedactBullet/;
use Vote::Count::Method::CondorcetIRV;
use Try::Tiny;

our $VERSION='1.07';

# no warnings 'uninitialized';
no warnings qw/experimental/;

=head1 NAME

Vote::Count::Method::CondorcetVsIRV

=head1 VERSION 1.07

=cut

# ABSTRACT: Condorcet versus IRV

=pod

=head1 SYNOPSIS

  use Vote::Count::Method::CondorcetVsIRV;

  my $Election = Vote::Count::Method::CondorcetVsIRV->new( ... );
  my $result = $Election->CondorcetVsIRV();
  or
  my $Election = Vote::Count->new( TieBreakMethod => 'approval' );
  my $result = $Election->CondorcetVsIRV( relaxed => 1 );
  equivalent to default:
  my $result = $Election->CondorcetVsIRV( relaxed => 0, smithsetirv => 0 );

  say $result->{'winner'};

  $Election->WriteAllLogs();

Returns a HashRef with a key for winner.

=head1 Method Common Name: Condorcet vs IRV

=head2 Method Summary

Determine if the Condorcet Winner needed votes from the IRV winner, elect the Condorcet Winner if there was not a later harm violation, elect the IRV winner if there was.

The Relaxed Later Harm option will select the Condorcet Winner when their margin of victory over the IRV Winner is greater than the number of later votes they need from the IRV Winner to be a Condorcet Winner.

This is a Redacting Condorcet Method because it uses Ballots which have been redacted for Later Harm effect.

=head2 Method Description

The method looks for a Condorcet Winner, if there is none it uses IRV to find the winner. If there is a Condorcet Winner it uses standard IRV to find the IRV winner. When the two winners do not match, it copies the ballots and redacts the later choice from those ballots that indicated both. It then determines if one of the two choices is a Condorcet Winner, if not it determines if one of them would win IRV. If either choice is the winner with redacted ballots, they win. If neither wins, the Condorcet Winner dependended on a Later Harm effect against the IRV winner, and the IRV Winner is elected.

With Relaxed Later Harm, when neither choice wins the redacted ballots, takes the greatest loss by the Condorcet Winner in the redacted matrix and compares it to their margin of victory over the IRV winner. If the victory margin is greater the Condorcet Winner is elected.

It is optional to use Smith Set IRV for the case where there is no Condorcet Winner and for the redacted confirmation. Unfortunately, when there is a Condorcet Winner Smith Set IRV cannot be used to find the IRV Winner without temporarily dropping the Condorcet Winner, which would prevent them from confirming via IRV.

The 'simple' option only redacts ballots that are first choice for the IRV winner.

=head1 Criteria

=head2 Simplicity

This is a medium complexity method. It builds on simpler methods but has a significant number of steps and branches.

=head2 Later Harm

This method meets Later Harm with the default strict option.

The relaxed option allows a finite Later Harm effect.

Using the TCA Floor Rule and or Smith Set IRV add small Later Harm effects.

=head2 Condorcet Criteria

This method only meets Condorcet Loser, when the IRV winner is chosen of the Condorcet Winner, the winner is outside the Smith Set.
Meets Condorcer Winner, Condorcet Loser, and Smith.

=head2 Consistency

Because this method chooses between the outcomes of two different methods, it inherits the consistency failings of both. It improves clone handling versus IRV, because in cases where the most supported clone loses IRV, it is often a Condorcet Winner. Likely there is overall improvement vs IRV.

=head2 Utility

Condorcet Vs IRV almost always picks the IRV Winner over the Condorcet Winner, on those occasions that it does overturn IRV it should be considered a success.

The ability to allow an optional tolerance for Later Harm is unique and powerful. The importance of Later Harm is the incentive it creates for strategic voting. To obtain sincere ballots in an election that is likely to be close with more than two significant choices, the voters must percieve the risk of not ranking a supported choice to be greater than the later harm risk. The relaxed option creates a reasonable tolerance for later harm. Notably in the Burlington 2009 Mayor Election where disatisfaction with winner resulted in the repeal of IRV, the Later Harm effect was significant and Condorcet Vs IRV confirms the IRV winner, use of Condorcet Vs IRV would have shown why the IRV decision was correct.

The Simple variant is slightly easier to comprehend. It provides a Later Harm balance by only protecting the first choice votes of the IRV winner. It gains the Condorcet advantage over IRV in resolving Cloning groups.

=head1 Implementation

Details specific to this implementation.

The Tie Breaker is defaulted to (modified) Grand Junction for resolvability. Any Tie Breaker supported by Vote::Count::TieBreaker may be used, except that 'all' should not be used.

=head2 Function Name: CondorcetVsIRV

Runs the election, returns a hashref containing the winner, similar to how other Vote::Count Methods such as RunIRV behave.

=head3 Arguments for CondorcetVsIRV()

=over

=item* relaxed

=item* simple

=item* smithsetirv

=back

=head2 LogTo, LogPath, LogBaseName, LogRedactedTo

The first three behave as normal Vote::Count::Log methods, except that the default is /tmp/condorcetvsirv.

LogRedactedTo defaults to appending _redacted into the log names for the  redacted election, it can be overridden by setting a value (which should be /path/basename) like LogTo.

=head2 WriteLog WriteAllLogs

WriteLog behaves normally, there is a log set for the CondorcetVSIRV object as well as child logs for the Election and RedactedElection, each of which has a set of logs for PairMatrix as well. WriteAllLogs will write all of these logs.

=cut

# LogTo over-writes role LogTo changing default filename.
has 'LogTo' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/tmp/condorcetvsirv',
);

has 'LogRedactedTo' => (
    is      => 'lazy',
    is      => 'rw',
    isa     => 'Str',
    builder => '_setredactedlog',
);

sub _setredactedlog ( $self ) {
    # There is a bug with LogTo being uninitialized despite having a default
    my $logto
        = defined $self->LogTo()
        ? $self->LogTo() . '_redacted'
        : '/tmp/condorcetvsirv_redacted';
    return $logto;
}

has 'TieBreakMethod' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'grandjunction',
);

has 'BallotSet' => ( is => 'ro', isa => 'HashRef', required => 1 );

has 'Active' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_InitialActive',
);

has 'SimpleCondorcetVsIRV' => (
  is   => 'ro',
  isa  => 'Bool',
  default => 0,
);

sub _InitialActive ( $I ) { return dclone $I->BallotSet()->{'choices'} }

sub SetActive ( $I, $active ) {
    $I->{'Active'} = dclone $active;
    $I->{'Election'}->SetActive($active);
    if ( defined $I->{'RedactedElection'} ) {
        $I->{'RedactedElection'}->SetActive($active);
    }
}

sub ResetActive ( $self ) {
    my $new = dclone $self->BallotSet()->{'choices'};
    $self->SetActive($new);
    return $new;
}

# sub ResetActive ( $self ) { return dclone $self->BallotSet()->{'choices'} }

sub _CVI_IRV ( $I, $active, $smithsetirv ) {
    my $WonIRV    = undef;
    my $irvresult = undef;
    if ($smithsetirv) {
        # smithirv needs to match irv args.
        $irvresult = $I->SmithSetIRV( $I->TieBreakMethod() );
    }
    else {
        $irvresult = $I->RunIRV( $active, $I->TieBreakMethod() );
    }
    return $irvresult->{'winner'} if $irvresult->{'winner'};
    $I->logt("IRV ended with a Tie.");
    $I->logt(
        "Active (Tied) Choices are: " . join( ', ', $irvresult->{'tied'} ) );
    $I->SetActiveFromArrayRef( $irvresult->{'tied'} );
    return 0;
}

sub BUILD {
    my $self = shift;
    $self->{'Election'} = Vote::Count::Method::CondorcetIRV->new(
        BallotSet      => $self->BallotSet(),
        TieBreakMethod => $self->TieBreakMethod(),
        Active         => $self->Active(),
        BallotSetType  => 'rcv',
        LogTo          => $self->{'LogTo'} . '_unredacted',
    );
    $self->{'RedactedElection'} = undef,;
}

sub WriteAllLogs ($I) {
    $I->WriteLog();
    $I->Election()->WriteLog();
    $I->RedactedElection()->WriteLog();
    $I->Election()->PairMatrix()->WriteLog();
    $I->RedactedElection()->PairMatrix()->WriteLog();
}

sub Election ($self) { return $self->{'Election'} }

sub RedactedElection ( $self, $ballotset = undef, $active = undef ) {
    return $self->{'RedactedElection'};
}

sub CreateRedactedElection ( $self, $WonCondorcet, $WonIRV, $simpleflag=0 ) {
  my $ballotset = $simpleflag
    ? RedactBullet ( $self->BallotSet(), $WonIRV )
    : RedactPair( $self->BallotSet(), $WonCondorcet, $WonIRV );
  $self->{'RedactedElection'} = Vote::Count->new(
      BallotSet      => $ballotset,
      TieBreakMethod => $self->TieBreakMethod(),
      Active         => $self->Active(),
      BallotSetType  => 'rcv',
      LogTo          => $self->LogRedactedTo(),
  );
}

#  $I, $active, $smithsetirv
sub _CVI_RedactRun ( $I, $WonCondorcet, $WonIRV, $active, $options ) {
    my $smithsetirv
        = defined $options->{'smithsetirv'} ? $options->{'smithsetirv'} : 0;
    my $relaxed  = defined $options->{'relaxed'} ? $options->{'relaxed'} : 0;
    my $E        = $I->Election();
    my $R        = $I->RedactedElection();
    my $ConfirmC = $R->PairMatrix->CondorcetWinner();
    my $ConfirmI = _CVI_IRV( $R, $active, $smithsetirv );
    if ( $ConfirmC eq $WonCondorcet or $ConfirmC eq $WonIRV ) {
        $I->logt("Elected $ConfirmC, Redacted Ballots Condorcet Winner.");
        return $ConfirmC;
    }
    else {
        $ConfirmI = _CVI_IRV( $R, $active, $smithsetirv );
        if ( $ConfirmI eq $WonCondorcet or $ConfirmI eq $WonIRV ) {
            $I->logt("Elected $ConfirmI, Redacted Ballots IRV Winner.");
            return $ConfirmI;
        }
    }
    $ConfirmC = 'NONE' unless $ConfirmC;
    $I->logt("Neither $WonCondorcet nor $WonIRV were confirmed.");
    $I->logt(
        "Redacted Ballots Winners: Condorcet = $ConfirmC, IRV = $ConfirmI");
    if ($relaxed) {
        my $GreatestLoss = $R->PairMatrix()->GreatestLoss($WonCondorcet);
        my $Margin = $E->PairMatrix()->GetPairResult( $WonCondorcet, $WonIRV )
            ->{'margin'};
        $I->logt(
            "The margin of the Condorcet over the IRV winner was: $Margin");
        $I->logt(
            "$WonCondorcet\'s greatest loss with redacted ballots was $GreatestLoss."
        );
        if ( $Margin > $GreatestLoss ) {
            $I->logt("Elected: $WonCondorcet");
            return $WonCondorcet;
        }
    }
    $I->logt("Elected: $WonIRV");
    return $WonIRV;
}

sub CondorcetVsIRV ( $self, %args ) {
    my $E           = $self->Election();
    my $smithsetirv = defined $args{'smithsetirv'} ? $args{'smithsetirv'} : 0;
    my $simpleflag = defined $args{'simple'} ? $args{'simple'} : 0;
    my $active      = $self->Active();
    # check for majority winner.
    my $majority = $E->EvaluateTopCountMajority()->{'winner'};
    return $majority if $majority;
    my $WonIRV       = undef;
    my $WonCondorcet = $E->PairMatrix()->CondorcetWinner();
    if ($WonCondorcet) {
        $self->logt("Condorcet Winner is $WonCondorcet");
        # Even if SmithSetIRV requested, it would return the condorcet winner
        # We need to know if a different choice would win IRV.
        $WonIRV = $E->RunIRV( $active, $E->TieBreakMethod() )->{'winner'};
    }
    else {
        $self->logt("No Condorcet Winner");
        $WonIRV = _CVI_IRV( $E, $active, $smithsetirv );
        if ($WonIRV) {
            $self->logt("Electing IRV Winner $WonIRV");
            return { 'winner' => $WonIRV };
        }
        else {        ;
            $self->logt("There is no Condorcet or IRV winner.");
            return { 'winner' => 0 };
        }
    }

    # IRV private already logged tie, now return the false value.
    # Edge case IRV tie with Condorcet Winner, I guess CW wins?
    unless ($WonIRV) {
        if ($WonCondorcet) {
            $self->logt("Electing Condorcet Winner $WonCondorcet, IRV tied.");
            return { 'winner' => $WonCondorcet};
        }
        return { 'winner' => 0 };
    }
    if ( $WonIRV eq $WonCondorcet ) {
        $self->logt("Electing $WonIRV the winner by both Condorcet and IRV.");
        return { 'winner' => $WonIRV };
    }
    if ( $WonIRV and !$WonCondorcet ) {
        $self->logt(
            "Electing IRV Winner $WonIRV. There was no Condorcet Winner.");
        return { 'winner' => $WonIRV };
    }
    $self->CreateRedactedElection( $WonCondorcet, $WonIRV, $simpleflag );
    my $winner
        = $self->_CVI_RedactRun( $WonCondorcet, $WonIRV, $active, \%args );
    return { 'winner' => $winner };

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
