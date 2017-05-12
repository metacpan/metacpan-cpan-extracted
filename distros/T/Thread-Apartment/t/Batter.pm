package Batter;

use Thread::Apartment;
use Thread::Apartment::Server;

use base qw(Thread::Apartment::Server);

use strict;
use warnings;

sub report_result {
	my ($testtype, $testno, $result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $$testno # skip $testmsg for $testtype\n" :
			"ok $$testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print "not ok $$testno # $testmsg $notokmsg for $testtype\n";
	}
	$$testno++;
}

sub new {
	my ($class, $tac) = @_;
	my $obj = bless { _ready => 0 }, $class;
	$obj->set_client($tac);
	return $obj;
}
#
#	called by main harness to check if an async operation completed
#
sub async_ready { return $_[0]->{_ready}; }
#
#	called by main harness to install object under test
#
sub set_test_object { $_[0]->{_obj} = $_[1]; }

sub remove_test_object { delete $_[0]->{_obj}; }

sub run_simple_async {
	my ($self, $testno, $testtype) = @_;

#print STDERR "run simple async closure called with ", join(', ', @_),
#	" on ", $self->{_obj}, "\n";

	$self->{_ready} = undef;
	my $obj = $self->{_obj};
	my $id = $obj->ta_async_thirdBase(
		sub {
#			print STDERR "simple async closure called with ", join(', ', @_), "\n";
			$self->{_ready} = 1;
			my $res = shift;
			report_result($testtype, $testno, defined($res) && ($res eq 'thirdbase'), 'async closure');
		});
	print STDERR "can't async: $@\n" unless defined($id);
	return 1;
}

sub run_override_async {
	my ($self, $testno, $testtype) = @_;

	$self->{_ready} = undef;
	my $obj = $self->{_obj};
	my $id = $obj->ta_async_firstBase(
		sub {
			$self->{_ready} = 1;
			my $res = shift;
			report_result($testtype, $testno, ($res eq 'triple'), 'async override closure');
		});
	return 1;
}

sub run_inherited_async {
	my ($self, $testno, $testtype) = @_;

	$self->{_ready} = undef;
	my $obj = $self->{_obj};
	my $id = $obj->ta_async_secondBase(
		sub {
			$self->{_ready} = 1;
			my $res = shift;
			report_result($testtype, $testno, ($res eq 'secondbase'), 'async inherited closure');
		});
	return 1;
}

sub run_closure_args {
	my ($self, $testno, $testtype) = @_;

	$self->{_ready} = undef;
	my $obj = $self->{_obj};
	my $closure = $obj->get_closure();

	$closure->('first', 'second', 'third', 'home');

	report_result($testtype, $testno, 1, 'void closure w/ arguments');

	my @results = $closure->('first', 'second', 'third', 'home');

#	print STDERR "Result is ", join(', ', @results), "\n";

	report_result($testtype, $testno, (($results[3] eq 'first') &&
		($results[2] eq 'second') &&
		($results[1] eq 'third') &&
		($results[0] eq 'home')), 'wantarray closure w/ arguments');

	my $result = $closure->('first', 'second', 'third', 'home');

#	print STDERR "Result is $result\n";

	report_result($testtype, $testno, ($result eq 'emohdrihtdnocestsrif'), 'scalar closure w/ arguments');
#
#	quick simplex test
#
	$closure = $obj->get_simplex_closure();

	$closure->('first', 'second', 'third', 'home');

	report_result($testtype, $testno, 1, 'simplex closure');
	$self->{_ready} = 1;

	return 1;
}

1;
