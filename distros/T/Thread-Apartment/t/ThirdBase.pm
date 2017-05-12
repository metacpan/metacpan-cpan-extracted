package ThirdBase;

use SecondBase;
use HomeBase;
use OnDeck;
use Thread::Apartment;
use Thread::Apartment::Server;

our @ISA;
use base qw(SecondBase HomeBase Thread::Apartment::Server);

use strict;
use warnings;

sub new {
	my ($class, $tac, $case) = @_;
	my $obj = bless { _case => $case }, $class;
	$obj->set_client($tac);
	$obj->{_ondeck} = Thread::Apartment->new(
		AptClass => 'OnDeck',
		ThirdBase => $obj);
	return $obj;
}

sub thirdBase {
	my $obj = shift;
#	print STDERR "Got to third base\n";
	return ($obj->{_case} eq 'uc') ? 'THIRDBASE' : 'thirdbase';
}

sub firstBase {
	my $obj = shift;
	return ($obj->{_case} eq 'uc') ? 'TRIPLE' : 'triple';
}

sub steal {	# urgent
	my $obj = shift;
#	print STDERR "Steal Case is $obj->{_case}\n";
	return ($obj->{_case} eq 'uc') ? 'STEAL' : 'steal';
}

sub balk { 	# simplex
	my $obj = shift;
#
#	to prove a simplex occured, change case
#
#	print STDERR "Case was $obj->{_case}\n";
	$obj->{_case} = ($obj->{_case} eq 'uc') ? 'lc' : 'uc';
#	print STDERR "Case is $obj->{_case}\n";
	return 1;
}

sub walk {	# urgent simplex
	my $obj = shift;
	$obj->{_case} = 'lc';
	return 1;
}
#
#	get base class's methods as well as our own
#
sub get_simplex_methods {
	my $obj = shift;

	my %simplex = ();
	foreach my $class (@ISA) {
		next
			if (($class eq 'Thread::Apartment::Server') ||
				($class eq 'Thread::Apartment::IOServer'));
		next unless ${class}->can('get_simplex_methods');

		my $s = ${class}->get_simplex_methods();

		foreach (keys %$s) {
			$simplex{$_} = 1;
			$simplex{"$class::$_"} = 1
				unless ($s->{$_}=~/::/);
		}
	}
	$simplex{balk} = 1;
	$simplex{walk} = 1;
	$simplex{timeOut} = 1;
#	print STDERR join(', ', %simplex), "\n";
	return \%simplex;
}

sub get_urgent_methods {
	my $obj = shift;

	my %urgent = ();
	foreach my $class (@ISA) {
		next
			if (($class eq 'Thread::Apartment::Server') ||
				($class eq 'Thread::Apartment::IOServer'));
		next unless ${class}->can('get_urgent_methods');

		my $s = ${class}->get_urgent_methods();

		foreach (keys %$s) {
			$urgent{$_} = 1;
			$urgent{"$class::$_"} = 1
				unless ($s->{$_}=~/::/);
		}
	}
	$urgent{walk} = 1;
	$urgent{steal} = 1;
#	print STDERR join(', ', %urgent), "\n";
	return \%urgent;
}
#
#	test array returning
#
sub homeRun {
	return ('first', 'second', 'third', 'home');
}

sub timeOut {	# something that injects a wait
	my ($obj, $delay) = @_;
	sleep $delay;
	return 1;
}

sub delay {	# something that injects a wait
	my ($obj, $delay) = @_;
	sleep $delay;
	return 1;
}

sub _bunt {		# a private method
	my $obj = shift;
	return ($obj->{_case} eq 'uc') ? 'BUNT' : 'bunt';
}

sub triplePlay {
	my ($obj, $player, $args) = @_;

	return $args->{$player}->{Molina}->{Erstad};
}
#
#	test object returning
#
sub suicideSqueeze {
	my ($obj, $case) = @_;

	my $home = HomeBase->new($case);
	return $home;
}

sub getCase {
#	print STDERR "In ThirdBase::getCase ", threads->self()->tid(), "\n";
	return shift->{_case};
}

sub onDeck {
	my $obj = shift->{_ondeck};
#	print STDERR "In ThirdBase::onDeck at ", time(), ' ', threads->self()->tid(), "\n";
	my $val = $obj->ta_reentrant_onDeck();
	$val = 'undef' unless $val;
#	print STDERR "Return $val from ThirdBase::onDeck at ", time(), ' ', threads->self()->tid(), "\n";
	return 1;
}
#
#	use re-entrant method, cuz OnDeck
#	may be trying to call us first
#
sub batterUp {
	my $obj = shift->{_ondeck};
#	print STDERR "In ThirdBase::batterUp at ", time(), "\n";
	my $result = $obj->batterUp();
	$result = 'undef' unless defined $result;
#	print STDERR "ThirdBase::batterUp returning $result ", time(), "\n";
	return $result;
}

sub get_closure {
	my $obj = shift;
	return sub {
		return reverse @_;
	};
}

sub get_simplex_closure {
	my $obj = shift;
	return $obj->new_simplex_tacl(
		sub {
			return reverse @_;
		});
}

sub get_delay_closure {
	my $obj = shift;
	return sub {
		return $obj->delay(@_);
	};
}

sub cleanUp {
	my $self = shift;
#	print STDERR "Cleaning up for ", ref $self, "\n";
	my $ondeck = delete $self->{_ondeck};
	$ondeck->stop();
	$ondeck->join();
#	print STDERR "Cleaned up for ", ref $self, "\n";
	return 1;
}

1;
