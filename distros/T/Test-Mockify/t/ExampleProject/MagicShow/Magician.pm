package t::ExampleProject::MagicShow::Magician;
use t::ExampleProject::MagicShow::Rabbit;
use strict;
sub new {
    my $class = shift;
    my ($Rabbit) = @_;
    my $self  = bless ({
        'Rabbit' => $Rabbit ? $Rabbit : t::ExampleProject::MagicShow::Rabbit->new(),
    }, $class);
    return $self;
}

sub pullRabbit {
    my $self = shift;
    my $Say = 'Tada!';
    if($self->{'Rabbit'}->isSnappyToday()){
        return $Say.' ouch';
    }
    return $Say;
}

sub getLineUpName {
    my $self = shift;
    return 'Pulled bunny';
}

1;