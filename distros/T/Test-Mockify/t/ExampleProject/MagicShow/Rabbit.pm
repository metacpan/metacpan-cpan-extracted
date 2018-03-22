package t::ExampleProject::MagicShow::Rabbit;
use strict;
sub new {
    return bless({},$_[0]);
}
sub isSnappyToday {
    my $self = shift;
    if(int(rand(10)) > 5){ ## no critic (ProhibitMagicNumbers)
        return 1;
    }else{
        return 0;
    }
}

1;