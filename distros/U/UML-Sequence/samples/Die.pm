
    package Die;
#    use strict; use warnings;

    sub new {
        my $class      = shift;
        my $sides      = shift || 6; # make the default 6
        my $self       = {};
        $self->{SIDES} = $sides;

        return bless  $self, $class;
    }

    sub roll {
        my $self          = shift;
        my $random_number = rand;

        $self->{VALUE}    = int ($random_number * $self->{SIDES}) + 1;
        return $self->{VALUE};
    }

    1;
