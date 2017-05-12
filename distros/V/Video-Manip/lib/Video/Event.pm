package Video::Event;

use vars qw($VERSION @EXPORT);
$VERSION=0.01;
@EXPORT = qw(new setenvl buildcool);

sub new {
    my ($class, $point, $identifier, $envelope, $probability, $type) = @_;

    my $self = bless {}, ref($class) || $class;
    $self->{'time'} = $point;
    $self->{'type'} = $type;
    $self->{'identifier'} = $identifier;
    $self->{'probablity'} = $probability;
    $self->{'envelope'} = $envelope;
    $self->{'zerooverride'} = 0; #used for zeroing in commercials
    return $self;
}

sub setenvel {
    my ($self, $type) = @_;
    print "set envelope $self->{'envelope'} to $type ";
    $self->{'envelope'} = $self->{'envelope'}{$type};
    print "$self->{'envelope'}\n";
}

sub setenvelnew {
    my ($self, $envel) = @_;
    $self->{'envelope'} = $envel;
}

sub buildcool {
    my ($self, $coolness, $maxlength) = @_;
    $coolness->applybunch($self, $maxlength);
    return $coolness;
}

1;
