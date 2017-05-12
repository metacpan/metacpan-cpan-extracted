package WWW::Spinn3r::Common;
use Time::HiRes qw(time gettimeofday tv_interval);

sub debug { 

    my ($self, $msg) = @_;
    print "debug: (WWW::Spinn3r) $msg\n" if $self->{debug};

}

sub start_timer { 

    my ($self); 
    return { now => [gettimeofday] };

}

sub howlong { 

    my ($self, $time) = @_;
    my $interval = tv_interval ( $$time{now}, [gettimeofday] );
    my $m = sprintf("%5.3f", $interval);
    return $m;

}

1;
