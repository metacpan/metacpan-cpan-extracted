use strict;
use warnings;
use 5.024;
use feature qw /postderef signatures/;

package Vote::Count::Method::CondorcetVsIRV;
use namespace::autoclean;
use Moose;

with 'Vote::Count::Log';

use Storable 3.15 'dclone';
use Vote::Count::ReadBallots qw/read_ballots write_ballots/;
use Vote::Count::Redact qw/RedactSingle RedactPair RedactBullet/;
use Vote::Count::Method::CondorcetIRV;
use Try::Tiny;
use Data::Dumper;

our $VERSION='2.02';

# no warnings 'uninitialized';
no warnings qw/experimental/;

=head1 NAME

Vote::Count::Method::CondorcetVsIRV

=head1 VERSION 2.02

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

Condorcet vs IRV Methods determine if the Condorcet Winner needed votes from the IRV winner; electing the Condorcet Winner if there was not a later harm violation, electing the IRV winner if there was. If there is no Condorcet Winner the IRV Winner is chosen.

To determine if there was a violation the ballots of one or more choices are redacted, with later choice on those ballots removed.

With these methods it is also possible to allow a tolerance for Later Harm.

=head3 Double Redaction

The Double Redaction method (default) measures the later harm effect between a Condorcet Winner and the IRV Winner.

Considering the Margin of the Condorcet Winner over the IRV Winner and the number of votes needed by the Condorcet Winner from the IRV winner as measures of Preference for the Condorcet Winner and of Later Harm, it is also possible to establish a Later Harm Tolerance Threshold.

The Relaxed Later Harm option will select the Condorcet Winner when their margin of victory over the IRV Winner is greater than the number of later votes they need from the IRV Winner to be a Condorcet Winner. Although not presently implemented a different ratio or percentage could be used.

Because in most cases where the IRV and Condorcet winners are different there are Later Harm effects, without relaxed this method will almost always confirm the IRV winner.

=head3 Simple (Single Redaction)

This variation only redacts the ballots that choose the IRV Winner as their first choice. This gives the voters confidence that if their first choice wins by the later harm safe method, that their vote will not be used against that choice.

The simplest form is:

    1. Determine the IRV Winner

    2. Treating the ballots cast with the IRV Winner as their first choice as ballots cast only for the IRV Winner, determine the Condorcet Winner.

    3. Elect the Condorcet Winner, if there is none, elect the IRV Winner.

Unfortunately, this simplest form, in cases where more than one choice defeats the IRV Winner in pairing and later choices of the IRV Winner's ballots determine which becomes the Condorcet Winner, removes the supporters of the IRV Winner from the final decision.

The form implemented by Vote::Count is:

=over

1. Determine both the IRV and Condorcet Winner. If they are the same, elect that choice. If there is no Condorcet Winner, elect the IRV Winner.

2. Treating the ballots cast with the IRV Winner as their first choice as ballots cast for only the IRV Winner determine the Condorcet Winner.

3. If there is a Condorcet Winner, elect the first Condorcet Winner, if there is none, elect the IRV Winner. (The redaction cannot make the IRV Winner a Condorcet Winner if it isn't already one).

=back

=cut

=head1 Criteria

The double redaction version is later harm safe if the relaxed option is not used. The simple version later harm protects first choice votes only, it also does not protect the first Condorcet Winner's votes at all.

=head2 Simplicity

The simple version does not require Condorcet Loop resolution, and thus can be considered to be on par with Benham for complexity, and like Benham is Hand Countable. The double redaction version is more complex, but is perhaps more valuable as an approach for measuring later harm.

=head2 Later Harm

This method meets Later Harm with the default strict option.

The relaxed option allows a finite Later Harm effect.

Using the TCA Floor Rule and or Smith Set IRV add small Later Harm effects.

=head2 Condorcet Criteria

This method only meets Condorcet Loser, when the IRV winner is chosen instead of the Condorcet Winner, the winner may be outside the Smith Set.

=head2 Consistency

Because this method chooses between the outcomes of two different methods, it is subject to the consistency failings of both. Given that Cloning is an important consistency issue in real elections, the clone handling should be an improvement over IRV.

=head1 Implementation

Details specific to this implementation.

The Tie Breaker is defaulted to (modified) Grand Junction for resolvability. Any Tie Breaker supported by Vote::Count::TieBreaker may be used, 'all' and 'none' are not recommended.

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
        $irvresult = $I->SmithSetIRV( $I->TieBreakMethod() );
    }
    else {
        $irvresult = $I->RunIRV( $active, $I->TieBreakMethod() );
    }
    $I->logd( 'IRV Result: ' . Dumper $irvresult );
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
      LogTo          => $self->LogRedactedTo(),
  );
  $self->logd(
    'Created Redacted Election.',
    $self->{'RedactedElection'}->PairMatrix()->PairingVotesTable(),
    $self->{'RedactedElection'}->PairMatrix()->MatrixTable(),
    );
}

sub _CVI_RedactRun ( $I, $WonCondorcet, $WonIRV, $active, $options ) {
    my $smithsetirv
        = $options->{'smithsetirv'} ? 1 : 0;
    my $relaxed  = $options->{'relaxed'} ? $options->{'relaxed'} : 0;
    my $simpleflag  = $options->{'simple'} ? 1 : 0;
    my $E        = $I->Election();
    my $R        = $I->RedactedElection();
    my $ConfirmC = $R->PairMatrix->CondorcetWinner();
    my $ConfirmI = _CVI_IRV( $R, $active, $smithsetirv );
    if ( $ConfirmC ) {
      if ( $simpleflag ) {
        $I->logt("Elected $WonCondorcet, Redacted Ballots had a Condorcet Winner.");
        $I->logv("The Redacted Condorcet Winner was $ConfirmC.")
            if ( $ConfirmC ne $WonCondorcet);
        return $WonCondorcet ;
      } elsif ( $ConfirmC eq $WonCondorcet or $ConfirmC eq $WonIRV ) {
        $I->logt("Elected $ConfirmC, Redacted Ballots Condorcet Winner.");
        return $ConfirmC;
        }
    } else {
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

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

