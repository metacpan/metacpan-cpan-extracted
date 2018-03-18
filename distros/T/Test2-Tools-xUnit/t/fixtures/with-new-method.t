package Bar;

use Test2::Tools::xUnit;
use Test2::V0;
use Scalar::Util qw(blessed reftype);

sub new {
    my $class = shift;
    bless [], $class;
}

sub first_argument_should_be_bar_object : Test {
    my $self = shift;
    is blessed($self), 'Bar';
}

sub first_argument_should_be_reference_to_blessed_array : Test {
    my $self = shift;
    is reftype($self), 'ARRAY';
}

done_testing;
