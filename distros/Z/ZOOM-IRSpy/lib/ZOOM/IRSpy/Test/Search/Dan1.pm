
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Dan1;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;
    my @attrs = ( 1..27            # Dan-1
                );

    foreach my $attr (@attrs) {
	$conn->irspy_search_pqf("\@attr dan1 1=$attr mineral",
                                {'attr' => $attr}, {},
				ZOOM::Event::ZEND, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $attr = $test_args->{'attr'};

    my $n = $task->{rs}->size();
    $task->{rs}->destroy();
    $conn->log("irspy_test", "search on access-point $attr found $n record",
	       $n==1 ? "" : "s");
    update($conn, $attr, 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $attr = $test_args->{'attr'};

    $task->{rs}->destroy();
    $conn->log("irspy_test", "search on access-point $attr had error: ",
	       $exception);
    update($conn, $attr, 0);
    zoom_error_timeout_update($conn, $exception);

    ### How about TEST_BAD if $exception->code() == 121?
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub update {
    my ($conn, $attr, $ok) = @_;

    $conn->record()->store_result('search', 'set'       => 'dan-1',
                                            'ap'        => $attr,
                                            'ok'        => $ok);
}




1;
