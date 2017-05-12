
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Boolean;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;
    my %pqfs = ('and'   => '@and @attr 1=4 mineral @attr 1=4 water',
                'or'    => '@or @attr 1=4 mineral @attr 1=4 water',
                'not'   => '@not @attr 1=4 mineral @attr 1=4 water',
                'and-or'=> '@and @or @attr 1=4 mineral @attr 1=4 water ' .
                           '@attr 1=4 of' 
                );

    foreach my $operator (keys %pqfs) {
	$conn->irspy_search_pqf($pqfs{$operator},
                                {'operator' => $operator}, {},
				ZOOM::Event::ZEND, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $operator = $test_args->{'operator'};

    my $n = $task->{rs}->size();
    $task->{rs}->destroy();
    $conn->log("irspy_test", "search using boolean operator ", $operator,
                             " found $n record", $n==1 ? "" : "s");
    update($conn, $operator, 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $operator = $test_args->{'operator'};

    $task->{rs}->destroy();
    $conn->log("irspy_test", "search using boolean operator ", $operator,
                             " had error: ", $exception);
    update($conn, $operator, 0);
    zoom_error_timeout_update($conn, $exception);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub update {
    my ($conn, $operator, $ok) = @_;

    $conn->record()->store_result('boolean', 'operator' => $operator,
                                             'ok'       => $ok);
}


1;
