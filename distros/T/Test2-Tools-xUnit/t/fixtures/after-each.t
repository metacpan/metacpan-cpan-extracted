use Test2::Tools::xUnit;
use Test2::V0;

my $counter = 0;
my $after_each_one_counter = 0;
my $after_each_two_counter = 0;

sub test_one : Test {
    my $self = shift;
    is $after_each_one_counter, $counter, "after each one called $counter times so far";
    is $after_each_two_counter, $counter, "after each two called $counter times so far";
    $counter += 1;
    $self->{test} = $counter;
} 

sub test_two : Test {
    my $self = shift;
    is $after_each_one_counter, $counter, "after each one called $counter times so far";
    is $after_each_two_counter, $counter, "after each two called $counter times so far";
    $counter += 1;
    $self->{test} = $counter;
} 

sub after_each_one : AfterEach {
    my $self = shift;
    is $self->{test}, $counter, "\$self->{test} has value $counter";
    $after_each_one_counter++;
}

sub after_each_two : AfterEach {
    my $self = shift;
    is $self->{test}, $counter, "\$self->{test} has value $counter";
    $after_each_two_counter++;
}

done_testing;
