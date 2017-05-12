
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Record::Fetch;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

our $max_timeout_errors = $ZOOM::IRSpy::max_timeout_errors;

my @queries = (
	       "\@attr 1=4 mineral",
	       "\@attr 1=4 computer",
	       "\@attr 1=44 mineral", # Smithsonian doesn't support AP 4!
	       "\@attr 1=1016 water", # Connector Framework only does 1016
	       ### We can add more queries here
	       );

# Certain fetch attempts cause the connection to be lost (e.g. the
# decoding of OPAC records fails for the National Library of
# Education, Denmark (grundtvig.dpu.dk:2100/S), after which all
# subsequent fetches fail -- see bug #3548.  To amerliorate the
# consequences of this, we check the record syntaxes in order of
# importance and likelihood of not causing the connection to be
# dropped.  Of course, for well-behaved servers, this makes no
# difference at all.

#@syntax = qw(grs-1 sutrs usmarc xml); # simplify for debugging
my @syntax = (
	       'usmarc',
	       'canmarc',
	       'danmarc',
	       'ibermarc',
	       'intermarc',
	       'jpmarc',
	       'librismarc',
	       'mab',
	       'normarc',
	       'picamarc',
	       'rusmarc',
	       'swemarc',
	       'ukmarc',
	       'unimarc',
	       'sutrs',
	       'xml',
	       'grs-1',
	       'summary',
	       'opac',
	    );


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_search_pqf($queries[0], { queryindex => 0 }, {},
			    ZOOM::Event::ZEND, \&completed_search,
			    exception => \&completed_search);
}


sub completed_search {
    my($conn, $task, $udata, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test", "Fetch test search (", $task->render_query(), ") ",
	       ref $event && $event->isa("ZOOM::Exception") ?
	       "failed: $event" : "found $n records (event=$event)");

    # remember how often a target record hit a timeout
    if (ref $event && $event->isa("ZOOM::Exception")) {
	if ($event =~ /Timeout/i) {
	    $conn->record->zoom_error->{TIMEOUT}++;
            $conn->log("irspy_test", "Increase timeout error counter to: " . 
		$conn->record->zoom_error->{TIMEOUT});
        }
    }

    if ($n == 0) {
	$task->{rs}->destroy();
	my $qindex = $udata->{queryindex}+1;
	my $q = $queries[$qindex];
	return ZOOM::IRSpy::Status::TEST_SKIPPED
	    if !defined $q || $conn->record->zoom_error->{TIMEOUT} >= $max_timeout_errors;

	$conn->log("irspy_test", "Trying another search ...");
	$conn->irspy_search_pqf($queries[$qindex], { queryindex => $qindex }, {},
				ZOOM::Event::ZEND, \&completed_search,
				exception => \&completed_search);
	return ZOOM::IRSpy::Status::TASK_DONE;
    }

    foreach my $i (0 ..$#syntax) {
	my $syntax = $syntax[$i];
	$conn->irspy_rs_record($task->{rs}, 0,
			       { syntax => $syntax,
			         last => ($i == $#syntax) },
			       { start => 0, count => 1,
				 preferredRecordSyntax => $syntax },
                                ZOOM::Event::ZEND, \&record,
				exception => \&fetch_error);
    }

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub record {
    my($conn, $task, $udata, $event) = @_;
    my $syn = $udata->{'syntax'};
    my $rs = $task->{rs};

    my $record = _fetch_record($conn, $rs, 0, $syn);
    my $ok = 0;
    if (!$record || $record->error()) {
	$conn->log("irspy_test", "retrieval of $syn record failed: ",
		   defined $record ? $record->exception() :
				     $conn->exception());
    } else {
	$ok = 1;
	my $text = $record->render();
	$conn->log("irspy_test", "Successfully retrieved a $syn record");
	if (0) {
	    print STDERR "Hits: ", $rs->size(), "\n";
	    print STDERR "Syntax: ", $syn, "\n";
	    print STDERR $text;
	}
    }

    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => $ok);

    $rs->destroy() if $udata->{last};
    return ($udata->{last} ?
	    ZOOM::IRSpy::Status::TEST_GOOD :
	    ZOOM::IRSpy::Status::TASK_DONE);
}


# By the time this is called, the record has already been physically
# fetched from the server in the correct syntax, and placed in the
# result-set's cache.  But in order to actually get hold of it from
# that cache, we need to set the record-syntax again, to the same
# value, otherwise ZOOM will make a fresh request.
#
# ZOOM::IRSpy::Task::Retrieve sets options into the connection object
# rather than the result-set object (because it's a subclass of
# ZOOM::IRSpy::Task, which doesn't know about result-sets).  Therefore
# it's important that this function also set into the connection:
# otherwise any value subsequently set into the connection by
# ZOOM::IRSpy::Task::Retrieve will be ignored by ZOOM-C operations, as
# the value previously set into the result-set will override it.
# (This was the very subtle cause of bug #3534).
#
sub _fetch_record {
    my($conn, $rs, $index0, $syntax) = @_;

    my $oldSyntax = $conn->option(preferredRecordSyntax => $syntax);
    my $record = $rs->record(0);
    $oldSyntax = "" if !defined $oldSyntax;
    $conn->option(preferredRecordSyntax => $oldSyntax);

    return $record;
}


sub __UNUSED_search_error {
    my($conn, $task, $test_args, $exception) = @_;

    $conn->log("irspy_test", "Initial search failed: ", $exception);
    return ZOOM::IRSpy::Status::TEST_SKIPPED;
}


sub fetch_error {
    my($conn, $task, $udata, $exception) = @_;
    my $syn = $udata->{'syntax'};

    $conn->log("irspy_test", "Retrieval of $syn record failed: ", $exception);
    $conn->record()->store_result('record_fetch',
                                  'syntax'       => $syn,
                                  'ok'        => 0);
    $task->{rs}->destroy() if $udata->{last};
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
