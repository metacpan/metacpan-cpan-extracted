
package ZOOM::IRSpy;

use 5.008;
use strict;
use warnings;

use Data::Dumper;		# For debugging only
use File::Basename;
use XML::LibXSLT;
use XML::LibXML;
use XML::LibXML::XPathContext;
use ZOOM;
use Net::Z3950::ZOOM 1.13;	# For the ZOOM version-check only
use ZOOM::IRSpy::Node;
use ZOOM::IRSpy::Connection;
use ZOOM::IRSpy::Stats;
use ZOOM::IRSpy::Utils qw(cql_target render_record
			  irspy_xpath_context irspy_make_identifier
			  irspy_record2identifier calc_reliability_stats
			  modify_xml_document);

our @ISA = qw();
our $VERSION = '1.02';
our $irspy_to_zeerex_xsl = dirname(__FILE__) . '/../../xsl/irspy2zeerex.xsl';
our $debug = 0;
our $xslt_max_depth = 250;
our $max_timeout_errors = 3;


# Enumeration for callback functions to return
package ZOOM::IRSpy::Status;
sub OK { 29 }			# No problems, task is still progressing
sub TASK_DONE { 18 }		# Task is complete, next task should begin
sub TEST_GOOD { 8 }		# Whole test is complete, and succeeded
sub TEST_BAD { 31 }		# Whole test is complete, and failed
sub TEST_SKIPPED { 12 }		# Test couldn't be run
package ZOOM::IRSpy;


=head1 NAME

ZOOM::IRSpy - Perl extension for discovering and analysing IR services

=head1 SYNOPSIS

 use ZOOM::IRSpy;
 $spy = new ZOOM::IRSpy("target/string/for/irspy/database");
 $spy->targets(@targets);
 $spy->initialise("Main");
 $res = $spy->check();

=head1 DESCRIPTION

This module exists to implement the IRspy program, which discovers,
analyses and monitors IR servers implementing the Z39.50 and SRU/W
protocols.  It is a successor to the ZSpy program.

=cut

BEGIN {
    ZOOM::Log::mask_str("irspy");
    ZOOM::Log::mask_str("irspy_debug");
    ZOOM::Log::mask_str("irspy_event");
    ZOOM::Log::mask_str("irspy_unhandled");
    ZOOM::Log::mask_str("irspy_test");
    ZOOM::Log::mask_str("irspy_task");
}

sub new {
    my $class = shift();
    my($dbname, $user, $password, $activeSetSize) = @_;


    my @options;
    push @options, (user => $user, password => $password)
	if defined $user;

    my $conn = new ZOOM::Connection($dbname, 0, @options)
	or die "$0: can't connection to IRSpy database 'dbname'";

    my $xslt = new XML::LibXSLT;

    # raise the maximum number of nested template calls and variables/params (default 250)
    warn "raise the maximum number of nested template calls: $xslt_max_depth\n" if $debug;
    $xslt->max_depth($xslt_max_depth);

    $xslt->register_function($ZOOM::IRSpy::Utils::IRSPY_NS, 'strcmp',
                             \&ZOOM::IRSpy::Utils::xslt_strcmp);

    my $libxml = new XML::LibXML;
    warn "use irspy_to_zeerex_xsl xslt sheet: $irspy_to_zeerex_xsl\n" if $debug;
    my $xsl_doc = $libxml->parse_file($irspy_to_zeerex_xsl);
    my $irspy_to_zeerex_style = $xslt->parse_stylesheet($xsl_doc);

    my $this = bless {
	conn => $conn,
	query => "cql.allRecords=1", # unless overridden
	modn => undef,		# Filled in by restrict_modulo()
	modi => undef,		# Filled in by restrict_modulo()
	targets => undef,	# Filled in later if targets() is
				# called; used only to keep state from
				# targets() until initialise() is
				# called.
	connections => undef,	# Filled in by initialise()
	queue => undef,		# Filled in by initialise()
        libxml => $libxml,
        irspy_to_zeerex_style => $irspy_to_zeerex_style,
	test => undef,		# Filled in by initialise()
	timeout => undef,	# Filled in by initialise()
	tests => undef,		# Tree of tests to be executed
	activeSetSize => defined $activeSetSize ? $activeSetSize : 10,
    }, $class;
    $this->log("irspy", "starting up with database '$dbname'");

    return $this;
}

# wrapper to read the IRSpy database name from environment variable / apache config
sub connect_to_registry {
    my %args = @_;

    # XXX: we could also handle her: user, password, elementSetName

    my $database = $ENV{IRSpyDbName} || "localhost:8018/IR-Explain---1";

    return $database;
}

sub log {
    my $this = shift();
    ZOOM::Log::log(@_);
}


sub find_targets {
    my $this = shift();
    my($query) = @_;

    $this->{query} = $query;
}


# Explicitly nominate a set of targets to check, overriding the
# default which is to re-check everything in the database.  Each
# target already in the database results in the existing record being
# updated; each new target causes a new record to be added.
#
sub targets {
    my $this = shift();
    my(@targets) = @_;

    $this->log("irspy", "setting explicit list of targets ",
	       join(", ", map { "'$_'" } @targets));
    my @qlist;
    foreach my $target (@targets) {
	my($protocol, $host, $port, $db, $newtarget) =
	    _parse_target_string($target);
	if ($newtarget ne $target) {
	    $this->log("irspy_debug", "rewriting '$target' to '$newtarget'");
	    $target = $newtarget; # This is written through the ref
	}
	push @qlist, cql_target($protocol, $host, $port, $db);
    }

    $this->{targets} = \@targets;
    $this->{query} = join(" or ", @qlist);
}


# Also used by ZOOM::IRSpy::Record
sub _parse_target_string {
    my($target) = @_;

    my($protocol, $host, $port, $db) = ($target =~ /(.*?):(.*?):(.*?)\/(.*)/);
    if (!defined $host) {
	$port = 210;
	($protocol, $host, $db) = ($target =~ /(.*?):(.*?)\/(.*)/);
	$target = irspy_make_identifier($protocol, $host, $port, $db);
    }
    die "$0: invalid target string '$target'"
	if !defined $host;

    return ($protocol, $host, $port, $db, $target);
}


sub restrict_modulo {
    my $this = shift();
    my($n, $i) = @_;

    $this->{modn} = $n;
    $this->{modi} = $i;
}


# Records must be fetched for all records satisfying $this->{query} If
# $this->{targets} is already set (i.e. a specific list of targets to
# check was specified by a call to targets()), then new, empty records
# will be made for any targets that are not already in the database.
#
sub initialise {
    my $this = shift();
    my($tname) = @_;

    $tname = "Main" if !defined $tname;
    $this->{test} = $tname;
    $this->{tree} = $this->_gather_tests($tname)
	or die "No tests defined for '$tname'";
    $this->{tree}->resolve();
    #$this->{tree}->print(0);

    $this->{timeout} = "ZOOM::IRSpy::Test::$tname"->timeout();

    my @targets;
    my $targets = $this->{targets};
    if (defined $targets) {
	@targets = @$targets;
	delete $this->{targets};
    } else {
	my $rs = $this->{conn}->search(new ZOOM::Query::CQL($this->{query}));
	$this->log("irspy", "'", $this->{query}, "' found ",
		   $rs->size(), " target records");
	delete $this->{query};

	foreach my $i (1 .. $rs->size()) {
	    push @targets, render_record($rs, $i-1, "id");
	}
    }

    my $n = $this->{activeSetSize};
    $n = @targets if $n == 0 || $n > @targets;

    $this->{queue} = \@targets;
    $this->{connections} = [];
    while (@{ $this->{connections} } < $n) {
	my $conn = $this->_next_connection();
	last if !defined $conn;
	push @{ $this->{connections} }, $conn;
    }
}


sub _next_connection {
    my $this = shift();

    my $target;
    my $n = $this->{modn};
    my $i = $this->{modi};
    if (!defined $n) {
	$target = shift @{ $this->{queue} };
	return undef if !defined $target;
    } else {
	while (1) {
	    $target = shift @{ $this->{queue} };
	    return undef if !defined $target;
	    my $h = _hash($target);
	    my $hmodn = $h % $n;
	    last if $hmodn == $i;
	    #$this->log("irspy", "'$target' hash $h % $n = $hmodn != $i");
	}
    }

    die "oops -- target is undefined" if !defined $target;
    return create ZOOM::IRSpy::Connection($this, $target, async => 1,
					  timeout => $this->{timeout});
}


sub _hash {
    my($target) = @_;

    my $n = 0;
    foreach my $s (split //, $target) {
	$n += ord($s);
    }

    return $n;
}


sub _irspy_to_zeerex {
    my $this = shift();
    my($conn) = @_;

    my $save_xml = $ENV{IRSPY_SAVE_XML};
    my $irspy_doc = $conn->record()->{zeerex}->ownerDocument;

    if ($save_xml) {
	unlink('/tmp/irspy_orig.xml');
	open FH, '>/tmp/irspy_orig.xml'
	    or die "can't write irspy_orig.xml: $!";
	print FH $irspy_doc->toString();
	close FH;
    }
    my %params = ();
    my $result = $this->{irspy_to_zeerex_style}->transform($irspy_doc, %params);
    if ($save_xml) {
	unlink('/tmp/irspy_transformed.xml');
	open FH, '>/tmp/irspy_transformed.xml'
	    or die "can't write irspy_transformed.xml: $!";
	print FH $result->toString();
	close FH;
    }

    return $result->documentElement();
}


sub _rewrite_irspy_record {
    my $this = shift();
    my($conn) = @_;

    $conn->log("irspy", "rewriting XML record");
    my $rec = $this->_irspy_to_zeerex($conn);

    # Since IRSpy can run for a long time between writes back to the
    # database, it's quite possible for the server to have closed the
    # connection as idle.  So re-establish it if necessary.
    $this->{conn}->connect($conn->option("host"));

    _rewrite_zeerex_record($this->{conn}, $rec);
    $conn->log("irspy", "rewrote XML record");
}


my $_reliabilityField = {
    reliability => [ reliability => 0,
		      "Calculated reliability of server",
		      "e:serverInfo/e:reliability" ],
};

sub _rewrite_zeerex_record {
    my($conn, $rec, $oldid) = @_;

    # Add reliability score
    my $xc = irspy_xpath_context($rec);
    my($nok, $nall, $percent) = calc_reliability_stats($xc);
    modify_xml_document($xc, $_reliabilityField, { reliability => $percent });

    my $p = $conn->package();
    $p->option(action => "specialUpdate");
    my $xml = $rec->toString();
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();

    # This is the expression in the ID-making stylesheet
    # ../../zebra/zeerex2id.xsl
    my $id = irspy_record2identifier($xc);
    if (defined $oldid && $id ne $oldid) {
	warn "IDs differ (old='$oldid' new='$id')";
	_delete_record($conn, $oldid);
    }

    $p = $conn->package();
    $p->send("commit");
    $p->destroy();
    if (0) {
	$xml =~ s/&/&amp/g;
	$xml =~ s/</&lt;/g;
	$xml =~ s/>/&gt;/g;
	print "Updated $conn with xml=<br/>\n<pre>$xml</pre>\n";
    }
}


sub _delete_record {
    my($conn, $id) = @_;

    # We can't delete records using recordIdOpaque, since character
    # sets are handled differently here in extended services from how
    # they are used in the Alvis filter's record-parsing, and so
    # non-ASCII characters come out differently in the two contexts.
    # Instead, we must send a record whose contents indicate the ID of
    # that which we wish to delete.  There are two ways, both
    # unsatisfactory: we could either fetch the actual record them
    # resubmit it in the deletion request (which wastes a search and a
    # fetch) or we could build a record by hand from the parsed-out
    # components (which is error-prone and which I am not 100% certain
    # will work since the other contents of the record will be
    # different).  The former evil seems to be the lesser.

    warn "$conn deleting record '$id'";

    my $rs = $conn->search(new ZOOM::Query::CQL(cql_target($id)));
    die "no such ID '$id'" if $rs->size() == 0;
    my $rec = $rs->record(0);
    my $xml = $rec->render();

    my $p = $conn->package();
    $p->option(action => "recordDelete");
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();

    $p = $conn->package();
    $p->send("commit");
    $p->destroy();
}


# The approach: gather declarative information about test hierarchy,
# then go into a loop.  In the loop, we ensure that each connection is
# running a test, and within that test a task, until its list of tests
# is exhausted.  No individual test ever calls wait(): tests just queue
# up tasks and return immediately.  When the tasks are run (one at a
# time on each connection) they generate events, and it is these that
# are harvested by ZOOM::event().  Since each connection knows what
# task it is running, it can invoke the appropriate callbacks.
# Callbacks return a ZOOM::IRSpy::Status value which tells the main
# loop how to continue.
#
# Invariants:
#	While a connection is running a task, its current_task()
#	points at the task structure.  When it finishes its task, 
#	next_task() is pointed at the next task to execute (if there
#	is one), and its current_task() is set to zero.  When the next
#	task is executed, the connection's next_task() is set to zero
#	and its current_task() pointed to the task structure.
#	current_task() and next_task() are both zero only when there
#	are no more queued tasks, which is when a new test is
#	started.
#
#	Each connection's current test is stored in its
#	"current_test_address" option.  The next test to execute is
#	calculated by walking the declarative tree of tests.  This
#	option begins empty; the "next test" after this is of course
#	the root test.
#
sub check {
    my $this = shift();

    my $topname = $this->{tree}->name();
    my $timeout = $this->{timeout};
    $this->log("irspy", "beginnning with test '$topname' (timeout $timeout)");

    my $nskipped = 0;
    my @conn = @{ $this->{connections} };

    my $nruns = 0;
  ROUND_AND_ROUND_WE_GO:
    while (1) {
	my @copy_conn = @conn;	# avoid alias problems after splice()
	my $nconn = scalar(@copy_conn);

	foreach my $i0 (0 .. $#copy_conn) {
	    my $conn = $copy_conn[$i0];
	    #print "connection $i0 of $nconn/", scalar(@conn), " is $conn\n";
	    next if !defined $conn;

	    if (!$conn->current_task()) {
		if (!$conn->next_task()) {
		    # Out of tasks: we need a new test
		  NEXT_TEST:
		    my $address = $conn->option("current_test_address");
		    my $nextaddr;
		    if (!defined $address) {
			$nextaddr = "";
		    } else {
			$conn->log("irspy_test",
				   "checking for next test after '$address'");
			$nextaddr = $this->_next_test($address);
		    }

                    if (ZOOM::IRSpy::Test::zoom_error_timeout_check($conn)) {
		        $conn->log("irspy", "Got to many timeouts, stop testing");
		        undef $nextaddr;
                    }

		    if (!defined $nextaddr) {
			$conn->log("irspy", "has no more tests: removing");
			$this->_rewrite_irspy_record($conn);
			$conn->option(rewrote_record => 1);
			my $newconn = $this->_next_connection();
			if (!defined $newconn) {
			    # Do not destroy: needed for later sanity checks
			    splice @conn, $i0, 1;
			} else {
			    $conn->destroy();
			    $conn[$i0] = $newconn;
			    $conn[$i0]->option(current_test_address => "");
			    $conn[$i0]->log("irspy", "entering active pool - ",
					    scalar(@{ $this->{queue} }),
					    " targets remain in queue");
			}
			next;
		    }

		    my $node = $this->{tree}->select($nextaddr)
			or die "invalid nextaddr '$nextaddr'";
		    $conn->option(current_test_address => $nextaddr);
		    my $tname = $node->name();
		    $conn->log("irspy_test",
			       "starting test '$nextaddr' = $tname");
		    my $tasks = $conn->tasks();
		    my $oldcount = @$tasks;
		    "ZOOM::IRSpy::Test::$tname"->start($conn);
		    $tasks = $conn->tasks();
		    if (@$tasks > $oldcount) {
			# Prepare to start the first of the newly added tasks
			$conn->next_task($tasks->[$oldcount]);
		    } else {
			$conn->log("irspy_task",
				   "no tasks added by new test $tname");
			goto NEXT_TEST;
		    }
		}

		my $task = $conn->next_task();
		die "no next task queued for $conn" if !defined $task;

	        # do not run the next task if we got too many timeouts
                if (ZOOM::IRSpy::Test::zoom_error_timeout_check($conn)) {
                    $conn->log("irspy_task", "Got to many timeouts for this target, do not start a new task");
                    next;
                }

		$conn->log("irspy_task", "preparing task $task");
		$conn->next_task(0);
		$conn->current_task($task);
		$task->run();
	    }
	}

      NEXT_EVENT:
	my $i0 = ZOOM::event(\@conn);
	$this->log("irspy_event",
		   "ZOOM_event(", scalar(@conn), " connections) = $i0");
	if ($i0 < 1) {
	    my %messages = (
			    0 => "no events remain",
			    -1 => "ZOOM::event() argument not a reference",
			    -2 => "ZOOM::event() reference not an array",
			    -3 => "no connections remain",
			    -4 => "too many connections for ZOOM::event()",
			    );
	    my $message = $messages{$i0} || "ZOOM::event() returned $i0";
	    $this->log("irspy", $message);
	    last;
	}

	my $conn = $conn[$i0-1];
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	$conn->log("irspy_event", "event $ev ($evstr)");
	goto NEXT_EVENT if $ev != ZOOM::Event::ZEND;

	my $task = $conn->current_task();
	die "$conn has no current task for event $ev ($evstr)" if !$task;

	my $res;
	eval { $conn->check() };
	if ($@ && ref $@ && $@->isa("ZOOM::Exception")) {
	    my $sub = $task->{cb}->{exception};
	    die $@ if !defined $sub;
	    $res = &$sub($conn, $task, $task->udata(), $@);
	} elsif ($@) {
	    die "Unexpected non-ZOOM exception: " . ref($@) . " ($@)";
	} else {
	    my $sub = $task->{cb}->{$ev};
	    if (!defined $sub) {
		$conn->log("irspy_unhandled", "event $ev ($evstr)");
		next;
	    }

	    $res = &$sub($conn, $task, $task->udata(), $ev);
	}

	if ($res == ZOOM::IRSpy::Status::OK) {
	    # Nothing to do -- life continues

	} elsif ($res == ZOOM::IRSpy::Status::TASK_DONE) {
	    my $task = $conn->current_task();
	    die "no task for TASK_DONE on $conn" if !$task;
	    die "next task already defined for $conn" if $conn->next_task();
	    $conn->log("irspy_task", "completed task $task");
	    $conn->next_task($task->{next});
	    $conn->current_task(0);

	} elsif ($res == ZOOM::IRSpy::Status::TEST_GOOD ||
		 $res == ZOOM::IRSpy::Status::TEST_BAD) {
	    my $x = ($res == ZOOM::IRSpy::Status::TEST_GOOD) ? "good" : "bad";
	    $conn->log("irspy_task", "test ended during task $task ($x)");
	    $conn->log("irspy_test", "test completed ($x)");
	    $conn->current_task(0);
	    $conn->next_task(0);
	    if ($res == ZOOM::IRSpy::Status::TEST_BAD) {
		my $address = $conn->option('current_test_address');
		$conn->log("irspy", "top-level test failed!")
		    if $address eq "";
		my $node = $this->{tree}->select($address);
		my $skipcount = 0;
		while (defined $node->next() &&
		       length($node->next()->address()) >= length($address)) {
		    $conn->log("irspy_debug", "skipping from '",
			       $node->address(), "' to '",
			       $node->next()->address(), "'");
		    $node = $node->next();
		    $skipcount++;
		}

		$conn->option(current_test_address => $node->address());
		$conn->log("irspy_test", "skipped $skipcount tests");
		$nskipped += $skipcount;
	    }

	} elsif ($res == ZOOM::IRSpy::Status::TEST_SKIPPED) {
	    $conn->log("irspy_test", "test skipped during task $task");
	    $conn->current_task(0);
	    $conn->next_task(0);
	    $nskipped++;

	} else {
	    die "unknown callback return-value '$res'";
	}
    }

    $this->log("irspy", "exiting main loop");

    # Sanity checks: none of the following should ever happen
    my $finished = 1;
    $this->log("irspy", "performing end-of-run sanity-checks");
    foreach my $conn (@conn) {
	my $test = $conn->option("current_test_address");
	my $next = $this->_next_test($test);
	if (defined $next) {
	    $this->log("irspy",
		       "$conn (in test '$test') has queued test '$next'");
	    $finished = 0;
	}
	if (my $task = $conn->current_task()) {
	    $this->log("irspy", "$conn still has an active task $task");
	    $finished = 0;
	}
	if (my $task = $conn->next_task()) {
	    $this->log("irspy", "$conn still has a queued task $task");
	    $finished = 0;
	}
	if (!$conn->is_idle()) {
	    $this->log("irspy",
		       "$conn still has ZOOM-C level tasks queued: see below");
	    $finished = 0;
	}
	my $ev = $conn->peek_event();
	if ($ev != 0 && $ev != ZOOM::Event::ZEND) {
	    my $evstr = ZOOM::event_str($ev);
	    $this->log("irspy", "$conn has event $ev ($evstr) waiting");
	    $finished = 0;
	}
	if (!$conn->option("rewrote_record")) {
	    $this->log("irspy", "$conn did not rewrite its ZeeRex record");
	    $finished = 0;
	}
    }

    # This really shouldn't be necessary, and in practice it rarely
    # helps, but it's belt and braces.  (For now, we don't do this
    # hence the zero in the $nruns check).
    if (!$finished) {
	if (++$nruns < 0) {
	    $this->log("irspy", "back into main loop, ${nruns}th time");
	    goto ROUND_AND_ROUND_WE_GO;
	} else {
	    $this->log("irspy", "bailing after $nruns main-loop runs");
	}
    }

    # This shouldn't happen emit anything either:
    while ((my $i1 = ZOOM::event(\@conn)) > 0) {
	my $conn = $conn[$i1-1];
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	$this->log("irspy",
		   "$conn still has ZOOM-C level task queued: $ev ($evstr)")
	    if $ev != ZOOM::Event::ZEND;
    }

    return $nskipped;
}


# Exactly equivalent to ZOOM::event() except that it is tolerant to
# undefined values in the array being passed in.
#
sub __UNUSED_tolerant_ZOOM_event {
    my($connref) = @_;

    my(@conn, @map);
    foreach my $i (0 .. @$connref-1) {
	my $conn = $connref->[$i];
	if (defined $conn) {
	    push @conn, $conn;
	    push @map, $i;
	}
    }

    my $res = ZOOM::event(\@conn);
    return $res if $res <= 0;
    my $res2 = $map[$res-1] + 1;
    print STDERR "*** tolerant_ZOOM_event() returns $res->$res2\n";
    return $res2;
}


sub _gather_tests {
    my $this = shift();
    my($tname, @ancestors) = @_;

    die("$0: test-hierarchy loop detected: " .
	join(" -> ", @ancestors, $tname))
	if grep { $_ eq $tname } @ancestors;

    my $slashSeperatedTname = $tname;
    $slashSeperatedTname =~ s/::/\//g;
    my $fullName = "ZOOM/IRSpy/Test/$slashSeperatedTname.pm";

    eval {
	require $fullName;
    }; if ($@) {
	$this->log("irspy", "couldn't require '$fullName': $@");
	$this->log("warn", "can't load test '$tname': skipping",
		   $@ =~ /^Can.t locate/ ? () : " ($@)");
	return undef;
    }

    $this->log("irspy", "adding test '$tname'");
    my @subnodes;
    foreach my $subtname ("ZOOM::IRSpy::Test::$tname"->subtests($this)) {
	my $subtest = $this->_gather_tests($subtname, @ancestors, $tname);
	push @subnodes, $subtest if defined $subtest;
    }

    return new ZOOM::IRSpy::Node($tname, @subnodes);
}


# These next three should arguably be Node methods
sub _next_test {
    my $this = shift();
    my($address, $omit_child) = @_;

    # Try first child
    if (!$omit_child) {
	my $maybe = $address eq "" ? "0" : "$address:0";
	return $maybe if $this->{tree}->select($maybe);
    }

    # The top-level node has no successor or parent
    return undef if $address eq "";

    # Try next sibling child
    my @components = split /:/, $address;
    my $last = pop @components;
    my $maybe = join(":", @components, $last+1);
    return $maybe if $this->{tree}->select($maybe);

    # This node is exhausted: try the parent's successor
    return $this->_next_test(join(":", @components), 1)
}


sub _last_sibling_test {
    my $this = shift();
    my($address) = @_;

    return undef
	if !defined $this->_next_sibling_test($address);

    my $nskipped = 0;
    while (1) {
	my $maybe = $this->_next_sibling_test($address);
	last if !defined $maybe;
	$nskipped++;
	$address = $maybe;
	$this->log("irspy", "skipping $nskipped tests to '$address'");
    }

    return ($address, $nskipped);
}


sub _next_sibling_test {
    my $this = shift();
    my($address) = @_;

    my @components = split /:/, $address;
    my $last = pop @components;
    my $maybe = join(":", @components, $last+1);
    return $maybe if $this->{tree}->select($maybe);
    return undef;
}


=head1 SEE ALSO

ZOOM::IRSpy::Record,
ZOOM::IRSpy::Web,
ZOOM::IRSpy::Test,
ZOOM::IRSpy::Maintenance.

The ZOOM-Perl module,
http://search.cpan.org/~mirk/Net-Z3950-ZOOM/

The Zebra Database,
http://indexdata.com/zebra/

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
