package Video::FindEvent;

use vars qw($VERSION @EXPORTER);
$VERSION = 0.01;
@EXPORTER = qw(new configure foundevent);

use strict;
use Video::Event;
use Data::Dumper;

sub new {
    my ($class) = @_;
    my $self = bless {}, ref($class) || $class;
    $self->{'events'} = ();
    return $self;
}    

sub configure {
    my ($self, $args) = @_;
    foreach my $arg (keys %$args) {  
        $self->{$arg} = $$args{$arg};
    }
}

sub foundevent {
    #don't override
    my ($self, $time, $coolness, $probability, $boundary, $keepstate) = @_;
    if ($self->{'writefile '} ne '') {
        if ($$keepstate{'eventhandle'}) {
            my $FH = $$keepstate{'eventhandle'};
            print $FH "$time\n" if $boundary;
        }
        else {
            if ($boundary) {
                my $file = $self->{'writeto'};
                open FH, ">>$file.bdy";
                print FH "$time\n";
                close FH;
            }
        }
        my $hash = { 'time' => $time,
                     'probability' => $probability,
                     'boundary' => $boundary,
                     'coolness' => $coolness,
                     'envelope' => { 0 => 1 },
                   };
        my $event = Event->new($hash);
        if ($$keepstate{'eventarray'}) {
            push @{$$keepstate{'eventarray'}}, $event;
        }
        else {
            my $file = $self->{'writefile'};
            open GH, ">>$file.obj";
            my $dump = Dumper($event);
            print GH "$dump\n";
            close GH;
        }
    }
    return $keepstate;
}

1;
