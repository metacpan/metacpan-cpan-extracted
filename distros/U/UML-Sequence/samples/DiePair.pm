#    use strict; use warnings;
package DiePair;
use Die;

sub new {
    my $class  = shift;
    my $sides1 = shift || 6;
    my $sides2 = shift || 6;
    my $self   = {};
    $self->{DIE1} = Die->new($sides1);
    $self->{DIE2} = Die->new($sides2);
    return bless $self, $class;
}

sub roll {
    my $self   = shift;
    my $value1 = $self->{DIE1}->roll();
    my $value2 = $self->{DIE2}->roll();
    $self->{TOTAL} = $value1 + $value2;
    if ($value1 == $value2) {
        $self->{DOUBLES} = 1;
    }
    else {
        $self->{DOUBLES} = 0;
    }
    return ($self->{TOTAL}, $self->{DOUBLES});
}

sub was_it_doubles {
    my $self = shift;
    return $self->{DOUBLES};
}

1;

