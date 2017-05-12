
# This plugin tests searching on BIB-1 access-point 1011 (Date/time
# added to db), the significance of which is that this search
# "succeeds" on some of our test databases
# (e.g. bagel.indexdata.com:210/marc) and fails on others
# (e.g. z3950.loc.gov:7090/Voyager gives error 114 "Unsupported Use
# attribute").  This allows us to test IRSpy's differing behaviour
# when a test succeeds or fails.

package ZOOM::IRSpy::Test::Search::DBDate;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_search_pqf('@attr 1=1011 mineral', undef, {},
			    ZOOM::Event::ZEND, \&found,
			    "exception", \&error);
}


sub found {
    my($conn, $task, $__UNUSED_udata, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test",
	       "DB-date search found $n record", $n==1 ? "" : "s");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:search_dbdate ok='1'>" .
		       isodate(time()) . "</irspy:search_dbdate>");

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $__UNUSED_udata, $exception) = @_;

    $conn->log("irspy_test", "DB-date search had error: $exception");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:search_dbdate ok='0'>" .
		       isodate(time()) . "</irspy:search_dbdate>");
    zoom_error_timeout_update($conn, $exception);
    return ZOOM::IRSpy::Status::TEST_BAD;
}


1;
