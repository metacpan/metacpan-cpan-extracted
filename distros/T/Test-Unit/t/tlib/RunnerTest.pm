package RunnerTest;

use strict;

use Test::Unit::TestRunner;

use base 'Test::Unit::TestCase';

sub set_up {
    my $self = shift;
    open(DEVNULL, '>/dev/null') or die "Couldn't open(>/dev/null): $!";
    $self->{runner} = Test::Unit::TestRunner->new(\*DEVNULL);
}

sub tear_down {
    my $self = shift;
    close(DEVNULL);
}
    
sub test_reset_filtering {
    my $self = shift;

    $self->{runner}->filter('random_token');
    $self->{runner}->reset_filter;

    $self->assert(! $self->{runner}->start('FilteredSuite'),
                  "run wasn't supposed to succeed");
    my $result = $self->{runner}->result;
    $self->assert_num_equals(4, $result->run_count);
    $self->assert_num_equals(3, $result->error_count);
    $self->assert_num_equals(0, $result->failure_count);
}

sub test_filter_via_method_list {
    my $self = shift;

    $self->{runner}->filter('token_filtering_via_method_list');

    $self->assert(! $self->{runner}->start('FilteredSuite'),
                  "run wasn't supposed to succeed");
    my $result = $self->{runner}->result;
    $self->assert_num_equals(2, $result->run_count);
    $self->assert_num_equals(1, $result->error_count);
    $self->assert_num_equals(0, $result->failure_count);
}

sub test_filter_via_sub {
    my $self = shift;
    $self->{runner}->filter('token_filtering_via_sub');

    $self->assert(! $self->{runner}->start('FilteredSuite'),
                  "run wasn't supposed to succeed");
    my $result = $self->{runner}->result;
    $self->assert_num_equals(3, $result->run_count);
    $self->assert_num_equals(2, $result->error_count);
    $self->assert_num_equals(0, $result->failure_count);
}

sub test_filter_via_both {
    my $self = shift;
    $self->{runner}->filter(
        'token_filtering_via_method_list',
        'token_filtering_via_sub',
        'nonexistent_token', # this has to be allowed
    );

    $self->assert($self->{runner}->start('FilteredSuite'),
                  "run wasn't supposed to fail");
    my $result = $self->{runner}->result;
    $self->assert_num_equals(1, $result->run_count);
    $self->assert_num_equals(0, $result->error_count);
    $self->assert_num_equals(0, $result->failure_count);
}

sub test_filter_broken_token {
    my $self = shift;
    $self->{runner}->filter('broken_token');

    eval {
        $self->{runner}->start('FilteredSuite');
    };
    my $exception = $@; # have to save $@ otherwise the assertion messes it up
    $self->assert_str_equals(
        "Didn't understand filtering definition for token broken_token in FilteredSuite\n",
        $exception
    );
}

1;
