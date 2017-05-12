package Weixin::Client::Base;
use Time::HiRes;
use AE;
use Carp;
use JSON ();
sub now{
    my $self = shift;
    return int Time::HiRes::time() * 1000;
}
sub json_decode {
    my $self = shift; 
    my $json = shift;
    my $d;
    eval{
        $d = JSON->new->utf8->decode($json);
    };
    return $d;
}
sub json_encode {
    my $self = shift;
    my $d = shift;
    my $json; 
    eval{
        $json = JSON->new->utf8->encode($d);
    };
    return $json; 
}

sub timer {
    my $self = shift;
    my $delay = shift;
    my $callback = shift;
    my $rand_watcher_id = rand();
    $self->{_watchers}{$rand_watcher_id} = AE::timer $delay,0,sub{
        delete $self->{_watchers}{$rand_watcher_id};
        $callback->(); 
    };
    
}

sub timer2 {
    my $self = shift;
    my ($id,$interval,$callback) = @_;
    my $delay = 0;
    my $now = time;
    if(exists $self->{_intervals}{$id} and defined $self->{_intervals}{$id}{_last_dispatch_time}){
        $delay = $now<$self->{_intervals}{$id}{_last_dispatch_time} + $interval?    
                    $self->{_intervals}{$id}{_last_dispatch_time}+$interval - $now
                :   0;
        $self->timer($delay,sub{
            $self->{_intervals}{$id}{_last_dispatch_time} = time;
            $callback->();
        });
    }
    else{
        $self->{_intervals}{$id}{_last_dispatch_time} = time;
        $callback->();
    }
      
}

1;
