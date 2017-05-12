
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::CQL;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    ### More indexes could be added here
    my @indexes = qw(cql.serverChoice cql.anywhere cql.allRecords
		     rec.id
		     net.host net.port
		     dc.title dc.creator dc.description
		     zeerex.numberOfRecords zeerex.set
		     );

    foreach my $index (@indexes) {
	$conn->irspy_search(cql => "$index=mineral",
			    { index => $index }, {},
			    ZOOM::Event::ZEND, \&found,
			    exception => \&error);
    }
}


sub found {
    my($conn, $task, $udata, $event) = @_;
    my $index = $udata->{"index"};

    my $n = $task->{rs}->size();
    $task->{rs}->destroy();
    $conn->log("irspy_test",
	       "CQL search on '$index' found $n record", $n==1 ? "" : "s");
    $conn->record()->store_result("search_cql", index => $index, ok => 1);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $udata, $exception) = @_;
    my $index = $udata->{"index"};

    $task->{rs}->destroy();
    $conn->log("irspy_test", "CQL search on '$index' had error: $exception");
    $conn->record()->store_result("search_cql", index => $index, ok => 0);
    zoom_error_timeout_update($conn, $exception);
    return ZOOM::IRSpy::Status::TEST_BAD
	if $exception->code() == 11; # Unsupported query type

    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
