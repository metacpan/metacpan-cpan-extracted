package Video::Event::Manual;

use vars qw($VERSION @EXPORT);
$VERSION = 0.01;
@EXPORT = qw(new endtime tag gettag matches);

use base Video::Event;

sub new {
    my ($class, $time, $envelope, $probability, $type, $name) = @_;

=pod
don't confuse $probability with envelope for coolness function
$probability is the probability that the event actually happened,
independent of how interesting the event was.
=cut 

    my $self = bless {}, ref($class) || $class;
    $self->{'time'} = $time;
    $self->{'envelope'} = $envelope;
    $self->{'probability'} = $probability;
    $self->{'type'} = $type if $type;
    $self->{'name'} = $name if $name;
    return $self;
}

sub endtime {
    my ($self, $eventtime, $coolness) = @_;
    my $totaltime = $eventtime - $self->{'time'};
    $self->{'endtime'} = $eventtime;
    $self->{'cool'} = $coolness;
    return $totaltime;
}    

sub tag {
    my ($self, $tag) = @_;
    if ($self->gettag()) {
        $self->{'tag'} .= $tag;
    }
    else {
        $self->{'tag'} = $tag;
    }
    return 1;
}    

sub matches {
    my ($self, $searchterm, $tags) = @_;
    if (ref $tags eq 'ARRAY' or $tags eq 'all') {
        foreach my $tag (@tags) {
            #hooray for perl 6
            return 1 if ($self->gettag() eq $tag);
        }
        return 0;
    }
    #if no tags specified, look in name
    else {
        return 1 if ($self->{'name'} =~ /$searchterm/);
        return 0;
    }
}

sub gettag {
    my ($self) = @_;
    return $self->{'tag'} if defined $self->{'tag'};
    return $self->{'name'};
}    

1;
