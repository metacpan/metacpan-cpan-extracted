package Choice;

use strict;
use warnings;

use Moose;

has 'value' => (is => "rw");

sub new
{
    my ($class,$value) = @_;
    my $self =
    {
        value => $value
    };
    bless $self,$class;
    return $self;
}

sub get_value
{
    my ($self) = shift;
    return $self->{value};
}

1;