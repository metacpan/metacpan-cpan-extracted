package TestInput;
use parent 'UniEvent::Streamer::Input';
use 5.012;

sub new {
    my ($class, $size, $speed) = @_;
    my $self = $class->SUPER::new();
    $self->{size} = $size;
    $self->{speed} = $speed;
    $self->{start_reading_cnt} = $self->{stop_reading_cnt} = 0;
    return $self;
}

sub start {
    my ($self, $loop) = @_;
    #say "start";
    my $timer = $self->{timer} = new UE::Timer($loop);
    $timer->start(0.001);
    $timer->callback(sub {
        #say "on read";
        if (!$self->{size}) {
            $self->handle_eof();
            $self->{timer}->stop();
            return;
        }
        $self->{speed} = $self->{size} if $self->{speed} > $self->{size};
        $self->handle_read('x' x $self->{speed});
        $self->{size} -= $self->{speed};
    });
    return undef;
}

sub start_reading {
    my $self = shift;
    #say "start reading";
    $self->{timer}->start(0.001);
    $self->{start_reading_cnt}++;
    return undef;
}

sub stop_reading {
    my $self = shift;
    #say "stop reading $self->{stop_reading_cnt}";
    $self->{timer}->stop();
    $self->{stop_reading_cnt}++;
}

sub stop {
    my $self = shift;
    #say "stop";
    $self->{timer}->stop();
}



package TestOutput;
use parent 'UniEvent::Streamer::Output';
use 5.012;

sub new {
    my ($class, $speed) = @_;
    my $self = $class->SUPER::new();
    $self->{speed} = $speed;
    return $self;
}

sub start {
    my ($self, $loop) = @_;
    #say "writer start";
    $self->{bufs} = [];
    $self->{timer} = UE::Timer->new($loop);
    $self->{timer}->callback(sub {
        shift @{$self->{bufs}};
        #say "on write que left ".$self->write_queue_size();
        $self->handle_write();
        $self->_write();
    });
    return undef;
}

sub stop {
    my $self = shift;
    #say "writer stop";
    $self->{timer}->stop();
}

sub write {
    my ($self, $data) = @_;
    my $len = length($data);
    #say "writer write $len, que=".$self->write_queue_size();
    push @{$self->{bufs}}, $len;
    $self->_write if @{$self->{bufs}} == 1;
    return undef;
}

sub _write {
    my $self = shift;
    return unless @{$self->{bufs}};
    my $len = $self->{bufs}[0];
    my $tmt = int($len / $self->{speed});
    #say "writer _write";
    $self->{timer}->once($tmt / 1000);
}

sub write_queue_size {
    my $self = shift;
    my $que = 0;
    $que += $_ for @{$self->{bufs}};
    return $que;
}

1;