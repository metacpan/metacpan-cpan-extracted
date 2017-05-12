# See the "Main" test package for documentation

### Too much common code with Fetch.pm: need to refactor

package ZOOM::IRSpy::Test::Record::OPAC;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

my @queries = (
	       "\@attr 1=4 mineral",
	       "\@attr 1=4 computer",
	       "\@attr 1=44 mineral", # Smithsonian doesn't support AP 4!
	       "\@attr 1=1016 water", # Connector Framework only does 1016
	       ### We can add more queries here
	       );

# We'd like to use this temporary-options hash to set
# preferredRecordSyntax, as well  But that doesn't work because the
# same value needs to be in force later on when we make the
# record_immediate() call, otherwise it misses its cache.
my %options = (
    piggyback => 1,
    count => 3,
#    preferredRecordSyntax => "opac"
    );

sub start {
    my $class = shift();
    my($conn) = @_;

    #$conn->option(apdulog => 1);
    $conn->option(preferredRecordSyntax => "opac");
    $conn->irspy_search_pqf($queries[0], { queryindex => 0 }, \%options,
			    ZOOM::Event::ZEND, \&completed_search,
			    exception => \&completed_search);
}


sub completed_search {
    my($conn, $task, $udata, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test", "OPAC test search (", $task->render_query(), ") ",
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
	    if !defined $q || $conn->record->zoom_error->{TIMEOUT} >= $ZOOM::IRSpy::max_timeout_errors;

	$conn->log("irspy_test", "Trying another search ...");
	$conn->irspy_search_pqf($queries[$qindex], { queryindex => $qindex }, \%options,
				ZOOM::Event::ZEND, \&completed_search,
				exception => \&completed_search);
	return ZOOM::IRSpy::Status::TASK_DONE;
    }

    # We have a result-set of three of more records, and we requested
    # that those records be included in the Search Response using
    # piggybacking.  Was it done?
    my $rec = $task->{rs}->record_immediate(2);
    my $ok = defined $rec && $rec->error() == 0;

    $task->{rs}->destroy();
    $conn->record()->store_result('multiple_opac', 'ok' => $ok);
    return $ok ? ZOOM::IRSpy::Status::TEST_GOOD : ZOOM::IRSpy::Status::TEST_BAD;
}


1;
