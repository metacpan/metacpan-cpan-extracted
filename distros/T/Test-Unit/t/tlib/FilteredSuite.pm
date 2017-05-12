package FilteredSuite;

use base 'Test::Unit::TestCase';

sub filter {{
    token_filtering_via_method_list => [
        qw/test_filtered_method1 test_filtered_method2/
    ],
    token_filtering_via_sub => sub {
        my ($method) = @_;
        return 1 if $method =~ /method3$/;
    },
    broken_token => 'nonsense',
}}

sub test_filtered_method1 {
    my $self = shift;
    die "test_filtered_method1 should get filtered via method list";
}

sub test_filtered_method2 {
    my $self = shift;
    die "test_filtered_method2 should get filtered via method list";
}

sub test_filtered_method3 {
    my $self = shift;
    die "test_filtered_method3 should get filtered via sub";
}

sub test_unfiltered_method1 {
    my $self = shift;
    $self->assert('trooooo');
}

1;
