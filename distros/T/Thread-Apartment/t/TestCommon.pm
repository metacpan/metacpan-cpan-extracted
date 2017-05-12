package TestCommon;
#
#	Thread::Apartment tests common functions
#
#	tests:
#	1. load OK
#	2. Create a wrapped object wo/ providing TQD/thread
#		(also creates a 2nd T::A object for async/closure testing)
#	3. Test simple method call
#	4. Test fully qualified method call
#	5. Test array-returning method call
#	6. Test attempt to access private method
#	7. Test for nonexistant method name
#	8. Test for AUTOLOADing method name
#	9. Test simplex method call
#	10. Test urgent method call
#	11. Test urgent, simplex method call
#	12. Test passing multiple, complex parameters
#	13. Test calling encapsulated TAS object
#	14. Test method call returning an error
#	15. Test method call returning an object
#	16. Test async method calls between objects
#		(also tests passing closures)
#	17. Test various closure calls between objects
#		(also tests returning closures)
#	18. Test timed method calls for timeout
#	19. Pass object to another thread and repeat tests (3-15)
#	20. Create TQD/thread externally and repeat tests (3-15)
#	21. Create an I/O object and repeat tests (3-15)
#	22. test ref counting
#
use Thread::Queue::Duplex;
use Thread::Apartment qw(start rendezvous
	rendezvous_any rendezvous_until rendezvous_any_until set_ta_debug);

use strict;
use warnings;

our $testtype;

sub report_result {
	my ($testno, $result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $$testno # skip $testmsg for $testtype\n" :
			"ok $$testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $$testno # $testmsg $notokmsg for $testtype\n";
	}
	$$testno++;
}
#
#	threaded version
#
sub run_thread {
	my ($tqd, $testno) = @_;
	$tqd->listen();
	my $req = $tqd->dequeue();
	my $id = shift @$req;
	my $obj = shift @$req;
	my $batter = shift @$req;
	my $installed = shift @$req;
	run($obj, $batter, $testno, $installed);
#
#	if in thread, respond
#
#print STDERR "run_thread responding\n";
	$tqd->respond($id, 'OK');
	return 1;
}
#
#	tests encapsulated in subroutine for reuse
#
sub run {
	my ($obj, $batter, $testno, $installed) = @_;
#
#	get the basics out of the way
#
	$installed = 'ThirdBase' unless $installed;
	report_result($testno, (ref $obj eq 'Thread::Apartment::Client'), 'ref');

	report_result($testno, $obj->isa($installed), 'isa()');

	report_result($testno, $obj->isa('FirstBase'), 'isa(base)');

	report_result($testno, (!$obj->isa('BadBase')), 'isa(bad base)');

	report_result($testno, $obj->can('walk'), 'can(good)');

	report_result($testno, (!$obj->can('punt')), 'can(bad)');

	report_result($testno, $obj->can('secondBase'), 'can(implicit inherited)');

#	report_result($testno, $obj->can('FirstBase::firstBase'), 'can(explicit inherited)');
#
#	basic calls
#
	my $result = $obj->thirdBase();
	report_result($testno, defined($result) && ($result eq 'thirdbase'), 'simple method', '', $@);

	$result = $obj->firstBase();
	report_result($testno, defined($result) && ($result eq 'triple'), 'overridden method', '', $@);

	$result = $obj->secondBase();
	report_result($testno, defined($result) && ($result eq 'secondbase'), 'inherited method', '', $@);
#
#	we can't yet support superclass methods...shouldn't be a huge
#	issue...
#
#	$result = $obj->FirstBase::firstBase();
#	report_result($testno, defined($result) && ($result eq 'firstbase'), 'explicit inherited method', '', $@);
#
#	array results
#
	my @results = $obj->homeRun();
	report_result($testno,
		((scalar @results == 4) &&
		($results[0] eq 'first') &&
		($results[1] eq 'second') &&
		($results[2] eq 'third') &&
		($results[3] eq 'home')),
		 'array returning method');
#
#	private method
#
	eval {
		$result = $obj->_bunt();
	};
	report_result($testno, defined($@), 'private method', $@, 'private method accessed');
#
#	bogus method
#
	eval {
		$result = $obj->touchDown();
	};
	report_result($testno, defined($@), 'bogus method', $@, 'bogus method accessed');
#
#	autoloaded method: we need to get an object that can autoload
#
	eval {
		$result = $obj->touchDown();
	};
	report_result($testno, defined($@), 'AUTOLOADed method', $@, 'AUTOLOADed method accessed');
#
#	try simplex
#
	eval {
		$obj->balk();
	};
	if ($@) {
		report_result($testno, undef, 'simplex method', undef, $@);
	}
	else {
#
#	verify the case changed
#
		$result = $obj->thirdBase();
		report_result($testno, ($result eq 'THIRDBASE'), 'simplex method', undef, 'case did not change!');
	}
#
#	try urgent:
#		call a wait to hold queue on other end
#		call a simplex
#		call a urgent
#		verify case of urgent response (should be upper)
#	NOTE: can only
#
	$obj->timeOut(3);	# wait 3 secs
	$obj->balk();		# would change case back to lower
	sleep 1;			# wait for thread to pick up the timeout...
#
#	should still be upper case
#
	$result = $obj->steal();
	report_result($testno, ($result eq 'STEAL'), 'urgent method', undef, 'case changed!');
#
#	now verify the case changed due to other simplex
#
	$result = $obj->thirdBase();
	report_result($testno, ($result eq 'thirdbase'), 'simplex method', undef, 'case did not change!');
#
#	try urgent simplex:
#		call a wait to hold queue on other end
#		call a simplex
#		call a urgent simplex => forces case to lower
#		verify case of urgent response (should be upper)
#
	$obj->balk();		# change case back to upper
	$obj->timeOut(3);	# wait 3 secs
	$obj->balk();		# would change case back to lower
	sleep 2;			# wait for thread to pick up the timeout...
	$obj->walk();		# but this forces lower, so prior balk should make upper
#
#	should still be upper case
#
	$result = $obj->thirdBase();
	report_result($testno, ($result eq 'THIRDBASE'), 'urgent simplex method', undef, 'case changed!');
	$obj->walk();		# restore lower case
#
#	complex params
#
	$result = $obj->triplePlay('Cabrerra',
		{
			Molina => {
				Erstad => {
					Molina => 23,
					Cabrerra => 14,
				},
				Cabrerra => {
					Molina => 23,
					Erstad => 22,
				},
			},
			Erstad => {
				Molina => {
					Erstad => 22,
					Cabrerra => 14,
				},
				Cabrerra => {
					Molina => 23,
					Erstad => 22,
				},
			},
			Cabrerra => {
				Erstad => {
					Molina => 23,
					Cabrerra => 14,
				},
				Molina => {
					Cabrerra => 14,
					Erstad => 22,
				},
			},
		});
	report_result($testno, ($result == 22), 'complex params');
#
#	encapsulated/reentrant TAS call:
#	NOTE 2 calls required in order to avoid deadlock
#
	my $val = $obj->onDeck();		# simplex to set on deck in encapsulated TAS
	$val = 'undef' unless $val;
	$result = $obj->batterUp();		# fetches the results w/ reentrant method
	report_result($testno, ($result eq 'batter up'), 'encapsulated/reentrant TAS');
#	$Thread::Queue::Duplex::tqd_debug = 0;
#
#	error test
#
	$result = $obj->error();
	report_result($testno, ((!defined($result)) && ($@ eq 'booted ball!')), 'error result');
#
#	object returning test
#
	$result = $obj->suicideSqueeze('uc');
	unless ($result) {
		report_result($testno, undef, 'object returning result', undef, $@);
	}
	else {
		$result = $result->homeBase();
		report_result($testno, (defined($result) && ($result eq 'HOMEBASE')),
			'object returning result');
	}
#
#	async tests
#
#	$Thread::Queue::Duplex::tqd_debug = 1;
#	set_ta_debug();
	$batter->set_test_object($obj);
	$batter->run_simple_async($testno, $testtype);
	my $count = 0;
	sleep 1,
	$count++
		until $batter->async_ready || ($count >= 10);

	report_result($testno, undef, 'async closure') unless $batter->async_ready;

	$batter->run_override_async($testno, $testtype);
	$count = 0;
	sleep 1,
	$count++
		until $batter->async_ready || ($count >= 10);

	report_result($testno, undef, 'async override closure') unless $batter->async_ready;

	$batter->run_inherited_async($testno, $testtype);
	$count = 0;
	sleep 1,
	$count++
		until $batter->async_ready || ($count >= 10);

	report_result($testno, undef, 'async inherited closure') unless $batter->async_ready;
#
#	closure argument test
#
	$batter->run_closure_args($testno, $testtype);
	$count = 0;
	sleep 1,
	$count++
		until $batter->async_ready || ($count >= 10);

	report_result($testno, undef, 'closure args') unless $batter->async_ready;

	$batter->remove_test_object();
#
#	response timeout tests
#
	$obj->timeOut(20);	# sleep 20 secs, which is > the AptTimeout of 10 secs
	$result = $obj->thirdBase();	# and execute something
	report_result($testno, (!defined($result)), 'AptTimeout timeout');
#
#	autoload, re-entrancy, and closure behavior tests
#	NOTE: reentrant/autoload get overridden internally
#
	my $ump = Thread::Apartment->new(
		AptClass => 'Umpire',
		AptTimeout => 10,
		AptReentrant => 0,
		AptAutoload => 0,
		AptClosureCalls => [ 'Simplex' ],
		AptParams => [ 'lc' ]
	);
	report_result($testno, $ump, 'create autoloading/reentrant/simplex closure\'ing object', '', $@);
#
#	test autoload
#
	$result = $ump->random_method();
	report_result($testno, ($result && ($result eq 'Method is random_method')),
		'autoloaded method call');
#
#	test re-entrancy
#
	$val = $ump->onDeck();		# simplex to set on deck in encapsulated TAS
	$val = 'undef' unless $val;
	$result = $ump->batterUp();		# fetches the results w/ reentrant method
	report_result($testno, ($result eq 'batter up'),
		'encapsulated/reentrant TAS for autoloading/reentrant object');
#
#	TO DO: test simplex closure
#
#	test async w/ rendezvous
#
	my @tacs = ();
	foreach (1..3) {
		push @tacs, Thread::Apartment->new(
			AptClass => 'ThirdBase',
			AptParams => ['lc']);
		die "Can't create: $@" unless $tacs[-1];
	}
#
#	default rendezvous
#
	my $async_closure = $tacs[2]->get_delay_closure();
	scalar start($tacs[$_])->delay(1 + $_)
		foreach (0..1);
	scalar start($async_closure)->(3);

	my @rdvus = rendezvous();
	if (scalar @rdvus != 3) {
		report_result($testno, undef, 'default rendezvous', '', 'didn\'t get all pending');
	}
	else {
		$_->get_pending_results()
			foreach (@rdvus);
		report_result($testno, 1, 'default rendezvous');
	}
#
#	default rendezvous w/ none active
#
	@rdvus = rendezvous();
	report_result($testno, (scalar @rdvus == 0), 'default rendezvous, all idle');
#
#	explicit rendezvous
#
	scalar start($tacs[$_])->delay(2 + $_)
		foreach (0..1);
	scalar start($async_closure)->(4);

	@rdvus = rendezvous($async_closure);
	if (scalar @rdvus != 1) {
		report_result($testno, undef, 'explicit rendezvous', '', 'should be 1 rdvu');
	}
	else {
		$_->get_pending_results()
			foreach (@rdvus);

		@rdvus = rendezvous($tacs[0], $tacs[1]);
		if (scalar @rdvus != 2) {
			report_result($testno, undef, 'explicit rendezvous', '', 'should be 2 rdvus');
		}
		else {
			$_->get_pending_results()
				foreach (@rdvus);
			report_result($testno, 1, 'explicit rendezvous');
		}
	}
#
#	default rendezvous_any
#
	scalar start($tacs[$_])->delay(2 + $_)
		foreach (0..2);

	@rdvus = rendezvous_any()
		while (scalar @rdvus < 3);

	$_->get_pending_results()
		foreach (@rdvus);
	report_result($testno, (scalar @rdvus == 3), 'default rendezvous_any');
#
#	explicit rendezvous_any; also tests attempted rendezvous
#	with idle thread
#
	scalar start($tacs[$_])->delay(2 + $_)
		foreach (0..2);

	@rdvus = rendezvous_any(@tacs)
		while (scalar @rdvus < 3);
	$_->get_pending_results()
		foreach (@rdvus);
	report_result($testno, (scalar @rdvus == 3), 'explicit rendezvous_any');
#
#	default rendezvous_until
#
	scalar start($tacs[$_])->delay(2 + $_)
		foreach (0..2);

	@rdvus = rendezvous_until(2);
	if (scalar @rdvus != 0) {
		report_result($testno, undef, 'default rendezvous_until',
			'', 'should have timed out');
	}
	else {
		@rdvus = rendezvous_until(6);
		$_->get_pending_results()
			foreach (@rdvus);
		report_result($testno, (scalar @rdvus == 3), 'default rendezvous_until');
	}
#
#	explicit rendezvous_until
#
	scalar start($tacs[$_])->delay(2 + $_)
		foreach (0..2);

	@rdvus = rendezvous_until(2, @tacs);
	if (scalar @rdvus != 0) {
		report_result($testno, undef, 'explicit rendezvous_until',
			'', 'should have timed out');
	}
	else {
		@rdvus = rendezvous_until(6, @tacs);
		$_->get_pending_results()
			foreach (@rdvus);
		report_result($testno, (scalar @rdvus == 3), 'explicit rendezvous_until');
	}
#
#	default rendezvous_any_until
#
	scalar start($tacs[$_])->delay(4 + $_)
		foreach (0..2);

	@rdvus = rendezvous_any_until(2);
	if (scalar @rdvus != 0) {
		report_result($testno, undef, 'default rendezvous_any_until',
			'', 'should have timed out');
	}
	else {
		@rdvus = rendezvous_any_until(8)
			while (scalar @rdvus < 3);
		$_->get_pending_results()
			foreach (@rdvus);
		report_result($testno, (scalar @rdvus == 3), 'default rendezvous_any_until');
	}
#
#	explicit rendezvous_any_until
#
	scalar start($tacs[$_])->delay(4 + $_)
		foreach (0..2);

	@rdvus = ();
	@rdvus = rendezvous_any_until(2, @tacs);
	if (scalar @rdvus != 0) {
		report_result($testno, undef, 'default rendezvous_until',
			'', 'should have timed out');
	}
	else {
		@rdvus = rendezvous_any_until(8, @tacs)
			while (scalar @rdvus < 3);
		$_->get_pending_results()
			foreach (@rdvus);
		report_result($testno, (scalar @rdvus == 3), 'explicit rendezvous_until');
	}
#
#	stop()/join() test
#
	$_->cleanUp(),
	$_->stop(),
	$_->join()
		foreach (@tacs);

#print STDERR "Cleaning up Umpire\n";
	$ump->cleanUp();
#print STDERR "Stopping Umpire\n";
	$ump->stop;
#print STDERR "Joining Umpire\n";
	$ump->join;

#print STDERR "Cleaning up ThirdBase\n";

	$obj->cleanUp();
#print STDERR "Stopping THirdBase\n";
	$obj->stop;
#print STDERR "Joining THirdBase\n";
	$obj->join;
#	print STDERR "Join complete\n";
	report_result($testno, 1, 'stop/join');
#
#	clean out the pool
#
	Thread::Apartment->destroy_pool();
	report_result($testno, 1, 'destroy_pool');
#
#	need to run an eviction test!!!
#	need a refcount test
#
	return 1;
}

1;