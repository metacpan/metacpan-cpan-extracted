use Test2::Tools::xUnit;
use Test2::V0;

my $counter = 0;

sub before_each_one : BeforeEach {
    my $self = shift;
    $self->{counter_one} = $counter;
}

sub before_each_two : BeforeEach {
    my $self = shift;
    $self->{counter_two} = $counter;
}

sub test_one : Test {
    my $self = shift;
    is $self->{counter_one}, $counter;
    is $self->{counter_two}, $counter;
    $counter += 1;
} 

sub test_two : Test {
    my $self = shift;
    is $self->{counter_one}, $counter;
    is $self->{counter_two}, $counter;
    $counter += 1;
} 

done_testing;
