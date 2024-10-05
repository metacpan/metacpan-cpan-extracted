package BenchCodeText;

use strict;
use warnings;
use Time::HiRes qw(time);

use base qw(Tk::Derived Tk::CodeText);

Construct Tk::Widget 'BenchCodeText';

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	
	$self->{TIMERSTART} = undef;
	$self->{TIMERSTOP} = undef;

#	$self->ConfigSpecs(
#		-linespercycle => ['PASSIVE', undef, undef, 1],
#	);
}

#sub highlightLoop {
#	my $self = shift;
#	if ($self->NoHighlighting) {
#		$self->LoopActive(0);
#		return
#	}
#	my $xt = $self->Subwidget('XText');
#	my $lpc = $self->cget('-linespercycle');
#	$lpc = 1 unless defined $lpc;
#	for (1 .. $lpc) {
#		my $colored = $self->Colored;
#		if ($colored <= $xt->linenumber('end - 1c')) {
#			$self->LoopActive(1);
#			$self->highlightLine($colored);
#			$colored ++;
#			$self->Colored($colored);
#		} else {
#			$self->LoopActive(0);
#		}
#		last unless $self->LoopActive;
#	}
#	$self->after($self->highlightinterval, ['highlightLoop', $self]) if $self->LoopActive;
#}

sub LoopActive {
	my ($self, $flag) = @_;
	if (defined $flag) {
		if ($flag) {
			$self->TimerStart unless $self->SUPER::LoopActive;
		} else {
			$self->TimerStop if $self->SUPER::LoopActive;
		}
		$self->{LOOPACTIVE} = $flag;
	}
	return $self->{LOOPACTIVE};
}

sub TimerStart {
	my $self = shift;
	my $time = time;
#	print "starting time $time\n";
	$self->{TIMERSTART} = $time;
}

sub TimerStop {
	my $self = shift;
	my $time = time;
#	print "ending time $time\n";
	$self->{TIMERSTOP} = $time;
}

sub TimerReset {
	my $self = shift;
	$self->{TIMERSTART} = undef;
	$self->{TIMERSTOP} = undef;
}

sub TimerResult {
	my $self = shift;
	my $start = $self->{TIMERSTART};
	return unless defined $start;
	my $stop = $self->{TIMERSTOP};
	return unless defined $stop;
	return $stop - $start
}
