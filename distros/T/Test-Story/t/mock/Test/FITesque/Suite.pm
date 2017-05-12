package Test::FITesque::Suite;
use Moose;
our $ADDED_TESTS = [];
sub add {
    push @{ shift->{data} }, @_;
}

sub run_tests {
    my $self = shift;
    my @results;
    foreach my $test (@{ $self->{data} }) {
        push @results, $test->data;
    }
    $Test::FITesque::Suite::ADDED_TESTS = \@results;
}

1;
